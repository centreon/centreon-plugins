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

package network::cisco::aci::apic::restapi::custom::api;

use strict;
use warnings;
use DateTime;
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
            'username:s' => { name => 'username' },
            'password:s' => { name => 'password' },
            'hostname:s' => { name => 'hostname' },
            'timeout:s'  => { name => 'timeout' },
            'port:s'     => { name => 'port'},
            'proto:s'    => { name => 'proto'}
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

    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : undef;
    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : undef;
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if (!defined($self->{username}) || $self->{username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --username option.');
        $self->{output}->option_exit();
    }
    if (!defined($self->{password}) || $self->{password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --password option.');
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});
    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = '';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub clean_access_token {
    my ($self, %options) = @_;

    my $datas = { last_timestamp => time() };
    $options{statefile}->write(data => $datas);
    $self->{access_token} = undef;
    $self->{http}->add_header(key => 'Cookie', value => undef);
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'cisco_aci_apic_' . md5_hex($self->{hostname}) . '_' . md5_hex($self->{username}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');
    my $last_timestamp = $options{statefile}->get(name => 'last_timestamp');

    if ($has_cache_file == 0 || !defined($access_token) || (($expires_on - time()) < 10)) {
        my $login = { aaaUser => { attributes => { name => $self->{username}, pwd => $self->{password} } } };
        my $post_json = JSON::XS->new->utf8->encode($login);

        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST',
            query_form_post => $post_json,
            url_path => '/api/aaaLogin.json'
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg => 'Cannot get token from API');
            $self->{output}->option_exit();
        }
        if (defined($decoded->{imdata}->[0]->{error}->{attributes})) {
            $self->{output}->add_option_msg(short_msg => "Error '" . uc($decoded->{imdata}->[0]->{error}->{attributes}->{code}) . " "
                . $decoded->{imdata}->[0]->{error}->{attributes}->{text} . "'");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{imdata}->[0]->{aaaLogin}->{attributes}->{token};
        my $datas = {
            last_timestamp => time(),
            access_token => $access_token, 
            expires_on => time() + $decoded->{imdata}->[0]->{aaaLogin}->{attributes}->{refreshTimeoutSeconds}
        };
        $options{statefile}->write(data => $datas);
    }

    $self->{access_token} = $access_token;
    $self->{http}->add_header(key => 'Cookie', value => 'APIC-Cookie=' . $self->{access_token});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    if (!defined($self->{access_token})) {
        $self->{access_token} = $self->get_access_token(statefile => $self->{cache});
    }

    my $content = $self->{http}->request(%options, warning_status => '', unknown_status => '', critical_status => '');

    # Maybe there is an issue with the access_token. So we retry.
    if ($self->{http}->get_code() != 200) {
        $self->clean_access_token(statefile => $self->{cache});
        $self->get_access_token(statefile => $self->{cache});
        $content = $self->{http}->request(%options);
    }
    
    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (defined($decoded->{imdata}->[0]) && defined($decoded->{imdata}->[0]->{error}->{attributes})) {
        $self->{output}->add_option_msg(short_msg => "Error '" . uc($decoded->{imdata}->[0]->{error}->{attributes}->{code}) . " " . $decoded->{imdata}->[0]->{error}->{attributes}->{text} . "'");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_fabric_health {
    my ($self, %options) = @_;

    my $response = $self->request_api(method => 'GET', url_path => '/api/class/fabricHealthTotal.json');
    return $response;
}

sub get_node_health_5m {
    my ($self, %options) = @_;

    my $response = $self->request_api(method => 'GET', url_path => '/api/class/fabricNodeHealth5min.json');
    return $response;
}

sub get_tenant_health {
    my ($self, %options) = @_;

    my $response = $self->request_api(method => 'GET', url_path => '/api/class/fvTenant.json?rsp-subtree-include=health,required');
    return $response;
}

1;

__END__

=head1 NAME

Cisco ACI APIC API Interface 

=head1 REST API OPTIONS

Cisco ACI APIC Interface 

=over 8

=item B<--hostname>

IP/FQDN of the Cisco ACI APIC

=item B<--username>

Username to connect to ACI APIC

=item B<--hostname>

Password to connect to ACI APIC

=item B<--timeout>

Set timeout in seconds (Default: 10).

=back

=head1 DESCRIPTION

B<custom>.

=cut
