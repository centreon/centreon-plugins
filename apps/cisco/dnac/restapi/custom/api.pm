#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package apps::cisco::dnac::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

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
        $options{options}->add_options(arguments => {
            'api-username:s'         => { name => 'api_username' },
            'api-password:s'         => { name => 'api_password' },
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port' },
            'proto:s'                => { name => 'proto' },
            'timeout:s'              => { name => 'timeout' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
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
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
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

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub json_decode {
    my ($self, %options) = @_;

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($options{content});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub clean_session_token {
    my ($self, %options) = @_;

    my $datas = { last_timestamp => time() };
    $options{statefile}->write(data => $datas);
    $self->{session_token} = undef;
    $self->{http}->add_header(key => 'X-Auth-Token', value => undef);
}

sub authenticate {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'cisco_dnac_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $session_token = $options{statefile}->get(name => 'session_token');

    if ($has_cache_file == 0 || !defined($session_token)) {
        my ($content) = $self->{http}->request(
            method => 'POST',
            query_form_post => '',
            url_path => '/dna/system/api/v1/auth/token',
            credentials => 1,
            basic => 1,
            username => $self->{api_username},
            password => $self->{api_password},
            warning_status => '',
            unknown_status => '',
            critical_status => ''
        );
        if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
            $self->{output}->add_option_msg(short_msg => "login error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded = $self->json_decode(content => $content);
        if (!defined($decoded->{Token})) {
            $self->{output}->add_option_msg(short_msg => 'error retrieving session_token');
            $self->{output}->option_exit();
        }

        $session_token = $decoded->{Token};
        my $datas = { last_timestamp => time(), session_token => $session_token };
        $options{statefile}->write(data => $datas);
    }

    $self->{session_token} = $session_token;
    $self->{http}->add_header(key => 'X-Auth-Token', value => $self->{session_token});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    if (!defined($self->{session_token})) {
        $self->authenticate(statefile => $self->{cache});
    }

    my ($content) = $self->{http}->request(
        url_path => '/dna/intent/api/v1' . $options{endpoint},
        get_param => $options{get_param},
        unknown_status => '',
        warning_status => '',
        critical_status => '' 
    );

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_session_token(statefile => $self->{cache});
        $self->authenticate(statefile => $self->{cache});
        ($content) = $self->{http}->request(
            url_path => '/dna/intent/api/v1' . $options{endpoint},
            get_param => $options{get_param},
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status},
        );
    }

    my $decoded = $self->json_decode(content => $content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => 'error while retrieving data (add --debug option for detailed message)');
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Cisco DNA Center Rest API

=head1 REST API OPTIONS

Cisco DNA Center Rest API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--api-username>

Set username.

=item B<--api-password>

Set password.

=item B<--timeout>

Set timeout in seconds (Default: 50).

=back

=head1 DESCRIPTION

B<custom>.

=cut
