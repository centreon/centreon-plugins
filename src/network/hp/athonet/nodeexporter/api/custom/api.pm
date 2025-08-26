#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::hp::athonet::nodeexporter::api::custom::api;

use base qw(cloud::prometheus::restapi::custom::api);

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;

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
            'hostname:s'      => { name => 'hostname' },
            'url-path:s'      => { name => 'url_path' },
            'port:s'          => { name => 'port' },
            'proto:s'         => { name => 'proto' },
            'api-username:s'  => { name => 'api_username' },
            'api-password:s'  => { name => 'api_password' },
            'api-backend:s'   => { name => 'api_backend' },
            'timeout:s'   => { name => 'timeout' },
            'timeframe:s' => { name => 'timeframe' },
            'step:s'      => { name => 'step' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
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
    $self->{option_results}->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{option_results}->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{url_path} = (defined($self->{option_results}->{url_path})) ? $self->{option_results}->{url_path} : '/core/prometheus/api/v1';
    $self->{option_results}->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_username} = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password} = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{api_backend} = (defined($self->{option_results}->{api_backend})) ? $self->{option_results}->{api_backend} : 'local';
    $self->{timeframe} = (defined($self->{option_results}->{timeframe})) ? $self->{option_results}->{timeframe} : undef;
    $self->{step} = (defined($self->{option_results}->{step})) ? $self->{option_results}->{step} : undef;
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_stat
us} : '%{http_code} < 200 or %{http_code} >= 300';
    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }   
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-username option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-password option.');
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{hostname} . ":" . $self->{option_results}->{port};
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{settings_done} = 1;
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile => 'hp_athonet_' . md5_hex($self->get_connection_info() . '_' . $self->{api_username}));
    my $access_token = $self->{cache}->get(name => 'access_token');
    my $refresh_token = $self->{cache}->get(name => 'refresh_token');
    my $md5_secret_cache = $self->{cache}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{api_username} . $self->{api_password});

    if (defined($refresh_token) && !defined($access_token)) {
        my $json_request = {
            refresh_token => $refresh_token
        };
        my $encoded;
        eval {
            $encoded = encode_json($json_request);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
            $self->{output}->option_exit();
        }

        my $content = $self->{http}->request(
            method => 'POST',
            url_path => '/core/pls/api/1/auth/refresh_token',
            query_form_post => $encoded,
            unknown_status => '',
            warning_status => '',
            critical_status => '',
            header => ['Content-Type: application/json']
        );

        if ($self->{http}->get_code() >= 200 && $self->{http}->get_code() < 300) {
            my $decoded;
            eval {
                $decoded = JSON::XS->new->utf8->decode($content);
            };
            if ($@) {
                $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
                $self->{output}->option_exit();
            }

            $access_token = $decoded->{access_token};
            my $datas = {
                updated => time(),
                access_token => $access_token,
                refresh_token => $decoded->{refresh_token},
                md5_secret => $md5_secret
            };
            $self->{cache}->write(data => $datas);
        }
    }

    if ($has_cache_file == 0 ||
        !defined($access_token) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)
        ) {
        my $json_request = {
            backend  => $self->{api_backend},
            username => $self->{api_username},
            password => $self->{api_password}
        };
        my $encoded;
        eval {
            $encoded = encode_json($json_request);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => 'cannot encode json request');
            $self->{output}->option_exit();
        }

        my $content = $self->{http}->request(
            method => 'POST',
            url_path => '/core/pls/api/1/auth/login',
            query_form_post => $encoded,
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status},
            header => ['Content-Type: application/json']
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $datas = {
            updated => time(),
            access_token => $access_token,
            refresh_token => $decoded->{refresh_token},
            md5_secret => $md5_secret
        };
        $self->{cache}->write(data => $datas);
    }

    return $access_token;
}

sub clean_access_token {
    my ($self, %options) = @_;

    my $refresh_token = $self->{cache}->get(name => 'refresh_token');
    my $md5_secret = $self->{cache}->get(name => 'md5_secret');

    my $datas = { updated => time(), refresh_token => $refresh_token, md5_secret => $md5_secret };
    $self->{cache}->write(data => $datas);
}

sub get_endpoint {
    my ($self, %options) = @_;

    $self->settings();
    my $access_token = $self->get_access_token();
    my ($content) = $self->{http}->request(
        url_path => $self->{url_path} . $options{url_path},
        header => ['Authorization: Bearer ' . $access_token],
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    # Maybe token is invalid. so we retry
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_access_token();
        $access_token = $self->get_access_token();
        $content = $self->{http}->request(
            url_path => $self->{url_path} . $options{url_path},
            header => ['Authorization: Bearer ' . $access_token],
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

    if ($decoded->{status} ne 'success') {
        $self->{output}->add_option_msg(short_msg => "Cannot get data: " . $decoded->{status});
        $self->{output}->option_exit();
    }
    
    return $decoded->{data};
}

1;

__END__

=head1 NAME

Prometheus Rest API

=head1 SYNOPSIS

Prometheus Rest API custom mode

=head1 REST API OPTIONS

Prometheus Rest API

=over 8

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour).

=item B<--step>

Set the step of the metric query (examples: '30s', '1m', '15m', '1h').

=item B<--hostname>

Prometheus hostname.

=item B<--url-path>

API url path (default: '/core/prometheus/api/v1')

=item B<--port>

API port (default: 443)

=item B<--proto>

Define https if needed (default: 'https')

=item B<--api-backend>

Define the backend for authentication (default: 'local')

=item B<--api-username>

Define the username for authentication

=item B<--api-password>

Define the password for authentication

=item B<--timeout>

Set HTTP timeout

=back

=head1 DESCRIPTION

B<custom>.

=cut
