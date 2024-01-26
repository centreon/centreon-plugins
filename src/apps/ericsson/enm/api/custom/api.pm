#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package apps::ericsson::enm::api::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Time::HiRes;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments =>  {
            'hostname:s'     => { name => 'hostname' },
            'port:s'         => { name => 'port' },
            'proto:s'        => { name => 'proto' },
            'api-username:s' => { name => 'api_username' },
            'api-password:s' => { name => 'api_password' },
            'timeout:s'      => { name => 'timeout' },
            'cache-use'      => { name => 'cache_use' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache_token} = centreon::plugins::statefile->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 50;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-username option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-password option.");
        $self->{output}->option_exit();
    }

    # we force to use storable module
    $self->{option_results}->{statefile_storable} = 1;
    $self->{cache_token}->check_options(option_results => $self->{option_results});
    $self->{cache}->check_options(option_results => $self->{option_results});
    return 0;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub login {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache_token}->read(statefile => 'ericsson_enm_' . md5_hex($self->{option_results}->{hostname} . '_' . $self->{api_username}));
    my $session_id = $self->{cache_token}->get(name => 'session_id');
    my $md5_secret_cache = $self->{cache_token}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_username} . $self->{api_password});

    if ($has_cache_file == 0 ||
        !defined($session_id) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)
        ) {
        $self->settings();
        my $content = $self->{http}->request(
            method => 'POST',
            url_path => '/login',
            post_param => ['IDToken1=' . $self->{api_username}, 'IDToken2=' . $self->{api_password}],
            critical_status => '',
            warning_status => '',
            unknown_status => ''
        );

        # 401 for failed auth
        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(short_msg => "Authentication error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my (@cookies) = $self->{http}->get_first_header(name => 'Set-Cookie');
        $session_id = '';
        foreach my $cookie (@cookies) {
            $session_id = $1 if ($cookie =~ /^iPlanetDirectoryPro=(.+?);/);
        }

        if (!defined($session_id) || $session_id eq '') {
            $self->{output}->add_option_msg(short_msg => 'Cannot get session id');
            $self->{output}->option_exit();
        }

        my $datas = {
            updated => time(),
            session_id => $session_id,
            md5_secret => $md5_secret
        };
        $self->{cache_token}->write(data => $datas);
    }

    return $session_id;
}

sub clean_session {
    my ($self, %options) = @_;

    my $datas = { updated => time() };
    $self->{cache_token}->write(data => $datas);
    $self->{session_id} = undef;
}

sub credentials {
    my ($self, %options) = @_;

    if (!defined($self->{session_id})) {
        $self->{session_id} = $self->login();
    }
}

sub execute_command {
    my ($self, %options) = @_;

    my $response = $self->{http}->request(
        method => 'POST',
        url_path => '/server-scripting/services/command',
        header => [
            'Accept: application/vnd.com.ericsson.oss.scripting+text;VERSION="1"',
            'X-Requested-With: XMLHttpRequest',
            'Cookie: iPlanetDirectoryPro=' . $self->{session_id}
        ],
        form => [
            { copyname => 'name', copycontents => 'command' },
            { copyname => 'command', copycontents => $options{command} },
            { copyname => 'stream_output', copycontents => 'true' },
            { copyname => 'requestSequence', copycontents => Time::HiRes::time() }
        ],
        critical_status => '',
        warning_status => '',
        unknown_status => ''
    );

    # Maybe token is invalid. so we retry
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_session();
        $self->credentials();
        $response = $self->{http}->request(
            method => 'POST',
            url_path => '/server-scripting/services/command',
            header => [
                'Accept: application/vnd.com.ericsson.oss.scripting+text;VERSION="1"',
                'X-Requested-With: XMLHttpRequest',
                'Cookie: iPlanetDirectoryPro=' . $self->{session_id}
            ],
            form => [
                { copyname => 'name', copycontents => 'command' },
                { copyname => 'command', copycontents => $options{command} },
                { copyname => 'stream_output', copycontents => 'true' },
                { copyname => 'requestSequence', copycontents => Time::HiRes::time() }
            ],
            critical_status => '',
            warning_status => '',
            unknown_status => ''
        );
    }

    if ($self->{http}->get_code() != 201) {
        $self->{output}->add_option_msg(short_msg => "execute-command issue");
        $self->{output}->option_exit();
    }

    return $response;
}

sub get_command_output {
    my ($self, %options) = @_;

    my $decoded;
    my $elements = [];
    while (1) {
        my $response = $self->{http}->request(
            method => 'GET',
            url_path => '/server-scripting/services/command/output/' . $options{command_id} . '/stream?',
            header => [
                'Accept: application/vnd.com.ericsson.oss.scripting.terminal+json;VERSION="3"',
                'X-Requested-With: XMLHttpRequest',
                'Cookie: iPlanetDirectoryPro=' . $self->{session_id}
            ],
            get_param => => ['_wait_milli=1000'],
            critical_status => '',
            warning_status => '',
            unknown_status => ''
        );
        # Maybe token is invalid. so we retry
        if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
            $self->clean_session();
            $self->credentials();
            $response = $self->{http}->request(
                method => 'GET',
                url_path => '/server-scripting/services/command/output/' . $options{command_id} . '/stream?',
                header => [
                    'Accept: application/vnd.com.ericsson.oss.scripting.terminal+json;VERSION="3"',
                    'X-Requested-With: XMLHttpRequest',
                    'Cookie: iPlanetDirectoryPro=' . $self->{session_id}
                ],
                get_param => => ['_wait_milli=1000'],
                critical_status => '',
                warning_status => '',
                unknown_status => ''
            );
        }

        if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
            $self->{output}->add_option_msg(short_msg => "get-command-output issue");
            $self->{output}->option_exit();
        }

        my $json;
        eval {
            $json = JSON::XS->new->utf8->decode($response);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => 'get-command-output: cannot decode response');
            $self->{output}->option_exit();
        }
        #_response_status = FETCHING, COMPLETE
        if ($json->{_response_status} eq 'COMPLETE') {
            $decoded = $json;
            unshift @{$decoded->{output}->{_elements}}, @$elements;
            last;
        } else {
            push @$elements, @{$json->{output}->{_elements}};
        }
    }

    return $decoded;
}

sub execute {
    my ($self, %options) = @_;

    $self->settings();
    $self->credentials();
    my $command_id = $self->execute_command(command => $options{command});
    return $self->get_command_output(command_id => $command_id);
}

sub parse_result {
    my ($self, %options) = @_;

    my $results = [];
    foreach my $group (@{$options{result}->{output}->{_elements}}) {
        foreach my $entry (@{$group->{_elements}}) {
            my $h = {};
            foreach (@{$entry->{_elements}}) {
                $h->{ $_->{_label}->[0] } = $_->{value};
            }
            push @$results, $h;
        }
    }

    return $results;
}

sub call_fruState {
    my ($self, %options) = @_;

    my $datas = $self->execute(
        command => 'cmedit get * FieldReplaceableUnit.(administrativeState,availabilityStatus,faultIndicator,hwTestResult,maintenanceIndicator,operationalIndicator,operationalState,specialIndicator,statusIndicator,userLabel) -t'
    );

    return $self->parse_result(result => $datas);
}

sub call_nodeSyncState {
    my ($self, %options) = @_;

    my $datas = $self->execute(
        command => 'cmedit get * CmFunction.syncStatus -t'
    );

    return $self->parse_result(result => $datas);
}

sub call_EUtranCellTDD {
    my ($self, %options) = @_;

    my $datas = $self->execute(
        command => 'cmedit get * EUtranCellTDD.(operationalstate,administrativestate,availabilityStatus,userlabel) -t'
    );

    return $self->parse_result(result => $datas);
}

sub cache_fruState {
    my ($self, %options) = @_;

    my $datas = $self->call_fruState();
    $self->write_cache_file(
        statefile => 'fruState',
        response => $datas
    );

    return $datas;
}

sub cache_nodeSyncState {
    my ($self, %options) = @_;

    my $datas = $self->call_nodeSyncState();
    $self->write_cache_file(
        statefile => 'nodeSyncState',
        response => $datas
    );

    return $datas;
}

sub cache_EUtranCellTDD {
    my ($self, %options) = @_;

    my $datas = $self->call_EUtranCellTDD();
    $self->write_cache_file(
        statefile => 'EUtranCellTDD',
        response => $datas
    );

    return $datas;
}

sub write_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_ericsson_enm_' . $self->get_hostname() . '_' . $options{statefile});
    $self->{cache}->write(data => {
        update_time => time(),
        response => $options{response}
    });
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_ericsson_enm_' . $self->get_hostname() . '_' . $options{statefile});
    my $response = $self->{cache}->get(name => 'response');
    if (!defined($response)) {
        $self->{output}->add_option_msg(short_msg => 'Cache file missing');
        $self->{output}->option_exit();
    }
    return $response;
}

sub get_fruState {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'fruState')
        if (defined($self->{option_results}->{cache_use}));
    return $self->call_fruState();
}

sub get_nodeSyncState {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'nodeSyncState')
        if (defined($self->{option_results}->{cache_use}));
    return $self->call_nodeSyncState();
}

sub get_EUtranCellTDD {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'EUtranCellTDD')
        if (defined($self->{option_results}->{cache_use}));
    return $self->call_EUtranCellTDD();
}

1;

__END__

=head1 NAME

ENM REST API

=head1 SYNOPSIS

Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

ENM hostname (required)

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-username>

API username.

=item B<--api-password>

API password.

=item B<--timeout>

Set HTTP timeout

=item B<--cache-use>

Use the cache file (created with cache mode). 

=back

=head1 DESCRIPTION

B<custom>.

=cut
