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

package apps::vtom::restapi::custom::api;

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
            'api-username:s'    => { name => 'api_username' },
            'api-password:s'    => { name => 'api_password' },
            'hostname:s'        => { name => 'hostname' },
            'port:s'            => { name => 'port' },
            'proto:s'           => { name => 'proto' },
            'timeout:s'         => { name => 'timeout' },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' },
            'token:s'                => { name => 'token' },
            'cache-use'              => { name => 'cache_use' }
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

    $self->{option_results}->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 30002;
    $self->{option_results}->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{option_results}->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';
    $self->{token} = $self->{option_results}->{token};

    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }

    $self->{cache_token}->check_options(option_results => $self->{option_results});
    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0 if (defined($self->{token}) && $self->{token} ne '');

    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-username option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-password option.');
        $self->{output}->option_exit();
    }

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port};
}

sub get_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile => 'vtom_' . md5_hex($self->get_connection_info() . '_' . $self->{api_username}));
    my $token = $self->{cache}->get(name => 'token');
    my $expires_on = $self->{cache}->get(name => 'expires_on');
    my $md5_secret_cache = $self->{cache}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_username} . $self->{api_password});

    if ($has_cache_file == 0 ||
        !defined($token) ||
        (time() > $expires_on) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)
        ) {
        my $json_request = {
            grant_type => 'password',
            username => $self->{api_username},
            password => $self->{api_password},
            tokenLifetime => 7200,
            tokenRefresh => \0
        };
        my $encoded;
        eval {
            $encoded = encode_json($json_request);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
            $self->{output}->option_exit();
        }

        $self->settings();
        my $content = $self->{http}->request(
            method => 'POST',
            url_path => '/vtom/public/auth/1.0/authorize',
            query_form_post => $encoded,
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }

        $token = $decoded->{access_token};
        my $datas = {
            updated => time(),
            token => $token,
            md5_secret => $md5_secret,
            expires_on => time() + $decoded->{expires_in}
        };
        $self->{cache}->write(data => $datas);
    }

    return $token;
}

sub clean_token {
    my ($self, %options) = @_;

    my $datas = { updated => time() };
    $self->{cache}->write(data => $datas);
}

sub credentials {
    my ($self, %options) = @_;

    my $creds = {};
    if (defined($self->{token}) && $self->{token} ne '') {
        $creds = {
            header => ['X-API-KEY: ' . $self->{token}],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        };
    } else {
        my $token = $self->get_token();
        $creds = {
            header => ['X-API-KEY: ' . $token],
            unknown_status => '',
            warning_status => '',
            critical_status => ''
        };
    }

    return $creds;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $creds = $self->credentials();
    my ($content) = $self->{http}->request(
        url_path => $options{endpoint},
        get_param => $options{get_param},
        %$creds
    );

    # Maybe token is invalid. so we retry
    if (defined($self->{token}) && $self->{token} ne '' && $self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_token();
        $creds = $self->credentials();
        $content = $self->{http}->request(
            url_path => $options{endpoint},
            get_param => $options{get_param},
            %$creds,
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->allow_nonref(1)->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub write_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_vtom_' . md5_hex($self->get_connection_info()) . '_' . $options{statefile});
    $self->{cache}->write(data => {
        update_time => time(),
        response => $options{response}
    });
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_vtom_' . md5_hex($self->get_connection_info()) . '_' . $options{statefile});
    my $response = $self->{cache}->get(name => 'response');
    if (!defined($response)) {
        $self->{output}->add_option_msg(short_msg => 'Cache file missing');
        $self->{output}->option_exit();
    }
    return $response;
}

sub call_jobs {
    my ($self, %options) = @_;

    return $self->request_api(
        endpoint => '/vtom/public/monitoring/1.0/jobs/status'
    );
}

sub cache_jobs {
    my ($self, %options) = @_;

    my $datas = $self->call_jobs();
    $self->write_cache_file(
        statefile => 'jobsStatus',
        response => $datas
    );

    return $datas;
}

sub get_jobs {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'jobsStatus')
        if (defined($self->{option_results}->{cache_use}));
    return $self->call_jobs();
}

1;

__END__

=head1 NAME

VTOM Rest API

=head1 REST API OPTIONS

VTOM Rest API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (default: 30002)

=item B<--proto>

Specify https if needed (default: 'https')

=item B<--api-username>

API username.

=item B<--api-password>

API password.

=item B<--token>

Use token authentication directly.

=item B<--timeout>

Set timeout in seconds (default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
