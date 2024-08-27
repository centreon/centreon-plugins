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

package apps::virtualization::hpe::simplivity::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = {};
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
            'hostname:s'     => { name => 'hostname' },
            'port:s'         => { name => 'port' },
            'proto:s'        => { name => 'proto' },
            'api-username:s' => { name => 'api_username' },
            'api-password:s' => { name => 'api_password' },
            'timeout:s'      => { name => 'timeout' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'OMNISTACK REST API OPTIONS', once => 1);

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
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify hostname option.');
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

sub get_connection_infos {
    my ($self, %options) = @_;

    return $self->{hostname} . '_' . $self->{http}->get_port();
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
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

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub clean_token {
    my ($self, %options) = @_;

    my $datas = {};
    $options{statefile}->write(data => $datas);
    $self->{access_token} = undef;
    $self->{http}->add_header(key => 'Authorization', value => undef);
}

sub get_auth_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => 'hpe_simplivity_api_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
    my $access_token = $options{statefile}->get(name => 'access_token');
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $md5_secret_cache = $self->{cache}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_username} . $self->{api_password});

    if ($has_cache_file == 0 || !defined($access_token) || (time() > $expires_on) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)) {
        my ($content) = $self->{http}->request(
            method => 'POST',
            hostname => 'simplivity@' . $self->{hostname},
            url_path => '/api/oauth/token',
            post_param => [
                'grant_type=password',
                'username=' . $self->{api_username},
                'password=' . $self->{api_password}
            ],
            warning_status => '',
            unknown_status => '',
            critical_status => ''
        );

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(short_msg => "Authentication error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded = $self->json_decode(content => $content);
        if (!defined($decoded->{access_token})) {
            $self->{output}->add_option_msg(short_msg => "Cannot get token");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $datas = {
            access_token => $access_token,
            expires_on => time() + $decoded->{expires_in},
            md5_secret => $md5_secret
        };
        $options{statefile}->write(data => $datas);
    }

    $self->{access_token} = $access_token;
    $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    if (!defined($self->{access_token})) {
        $self->get_auth_token(statefile => $self->{cache});
    }

    my $content = $self->{http}->request(
        method => 'GET',
        hostname => $self->{hostname},
        url_path => $options{endpoint},
        get_param => $options{get_param},
        warning_status => '',
        unknown_status => '',
        critical_status => ''
    );

    # Maybe there is an issue with the token. So we retry.
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_token(statefile => $self->{cache});
        $self->get_auth_token(statefile => $self->{cache});
        $content = $self->{http}->request(
            method => 'GET',
            hostname => $self->{hostname},
            url_path => $options{endpoint},
            get_param => $options{get_param},
            warning_status => '', unknown_status => '', critical_status => ''
        );
    }

    my $decoded = $self->json_decode(content => $content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => 'Error while retrieving data (add --debug option for detailed message)');
        $self->{output}->option_exit();
    }

    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        my $message = 'api request error';
        if (defined($decoded->{message})) {
            $message .= ': ' . $decoded->{message};
        }
        $self->{output}->add_option_msg(short_msg => $message);
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_hosts {
    my ($self, %options) = @_;

    return $self->request_api(
        endpoint => '/api/hosts',
        get_param => ['show_optional_fields=true', 'offset=0', 'limit=5000']
    );
}

sub get_host_hardware {
    my ($self, %options) = @_;

    return $self->request_api(
        endpoint => '/api/hosts/' . $options{id} . '/hardware',
        get_param => []
    );
}

sub get_omnistack_clusters {
    my ($self, %options) = @_;

    return $self->request_api(
        endpoint => '/api/omnistack_clusters',
        get_param => ['show_optional_fields=true', 'offset=0', 'limit=5000']
    );
}

sub get_virtual_machines {
    my ($self, %options) = @_;

    return $self->request_api(
        endpoint => '/api/virtual_machines',
        get_param => ['show_optional_fields=true', 'offset=0', 'limit=5000']
    );
}

1;

__END__

=head1 NAME

OmniStack API

=head1 SYNOPSIS

OmniStack api

=head1 OMNISTACK REST API OPTIONS

=over 8

=item B<--hostname>

OmniStack API hostname.

=item B<--port>

OmniStack API port (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-username>

OmniStack API username

=item B<--api-password>

OmniStack API password

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
