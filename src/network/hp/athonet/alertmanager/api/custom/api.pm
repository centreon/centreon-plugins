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

package network::hp::athonet::alertmanager::api::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use centreon::plugins::misc qw/is_empty json_decode json_encode/;

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
            'hostname:s'             => { name => 'hostname' },
            'url-path:s'             => { name => 'url_path', default => '/core/alertmanager/api/v2' },
            'port:s'                 => { name => 'port', default => 443 },
            'proto:s'                => { name => 'proto', default => 'https' },
            'api-username:s'         => { name => 'api_username' },
            'api-password:s'         => { name => 'api_password' },
            'timeout:s'              => { name => 'timeout', default => 10 },
            'unknown-http-status:s'  => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
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

    if (is_empty($self->{option_results}->{hostname})) {
        $self->{output}->option_exit(short_msg => "Need to specify hostname option.");
    }
    if (is_empty($self->{option_results}->{api_username})) {
        $self->{output}->option_exit(short_msg => 'Need to specify --api-username option.');
    }
    if (is_empty($self->{option_results}->{api_password})) {
        $self->{output}->option_exit(short_msg => 'Need to specify --api-password option.');
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ":" . $self->{option_results}->{port};
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{option_results}->{port};
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

    my $has_cache_file = $self->{cache}->read(statefile => 'hp_athonet_alertmanager_' . md5_hex($self->get_connection_info() . '_' . $self->{option_results}->{api_username}));
    my $access_token = $self->{cache}->get(name => 'access_token');
    my $refresh_token = $self->{cache}->get(name => 'refresh_token');
    my $md5_secret_cache = $self->{cache}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{option_results}->{api_username} . $self->{option_results}->{api_password});

    if (defined($refresh_token) && !defined($access_token)) {
        my $json_request = {
            refresh_token => $refresh_token
        };
        my $encoded = json_encode($json_request,
                      errstr => 'cannot encode json request',
                      output => $self->{output});

        my $content = $self->{http}->request(
            method          => 'POST',
            url_path        => '/core/pls/api/1/auth/refresh_token',
            query_form_post => $encoded,
            unknown_status  => '',
            warning_status  => '',
            critical_status => '',
            header          => [ 'Content-Type: application/json' ]
        );

        if ($self->{http}->get_code() >= 200 && $self->{http}->get_code() < 300) {
            my $decoded = json_decode($content,
                                      errstr => MSG_JSON_DECODE_ERROR,
                                      output => $self->{output});

            $access_token = $decoded->{access_token};
            my $datas = {
                updated       => time(),
                access_token  => $access_token,
                refresh_token => $decoded->{refresh_token},
                md5_secret    => $md5_secret
            };
            $self->{cache}->write(data => $datas);
        }
    }

    if ($has_cache_file == 0 ||
        !defined($access_token) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret)
    ) {
        my $json_request = {
            username => $self->{option_results}->{api_username},
            password => $self->{option_results}->{api_password}
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
            method          => 'POST',
            url_path        => '/core/pls/api/1/auth/login',
            query_form_post => $encoded,
            unknown_status  => $self->{option_results}->{unknown_http_status},
            warning_status  => $self->{option_results}->{warning_http_status},
            critical_status => $self->{option_results}->{critical_http_status},
            header          => [ 'Content-Type: application/json' ]
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->option_exit(short_msg => "Cannot decode json response");
        }

        $access_token = $decoded->{access_token};
        my $datas = {
            updated       => time(),
            access_token  => $access_token,
            refresh_token => $decoded->{refresh_token},
            md5_secret    => $md5_secret
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
        url_path        => $self->{option_results}->{url_path} . $options{endpoint},
        header          => [ 'Authorization: Bearer ' . $access_token ],
        unknown_status  => '',
        warning_status  => '',
        critical_status => ''
    );

    # Maybe token is invalid. so we retry
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_access_token();
        $access_token = $self->get_access_token();
        $content = $self->{http}->request(
            url_path        => $self->{option_results}->{url_path} . $options{endpoint},
            header          => [ 'Authorization: Bearer ' . $access_token ],
            unknown_status  => $self->{option_results}->{unknown_http_status},
            warning_status  => $self->{option_results}->{warning_http_status},
            critical_status => $self->{option_results}->{critical_http_status}
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

1;

__END__

=head1 NAME

Prometheus Rest API.

=head1 SYNOPSIS

Prometheus Rest API custom mode.

=head1 REST API OPTIONS

Prometheus Rest API.

=over 8

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour).

=item B<--step>

Set the step of the metric query (examples: C<30s>, C<1m>, C<15m>, C<1h>).

=item B<--hostname>

Prometheus hostname.

=item B<--url-path>

API url path (default: C<'/core/alertmanager/api/v2'>).

=item B<--port>

API port (default: 443).

=item B<--proto>

Define the protocol (default: 'https').

=item B<--api-username>

Define the username for authentication.

=item B<--api-password>

Define the password for authentication.

=item B<--timeout>

Set HTTP timeout.

=back

=head1 DESCRIPTION

B<custom>.

=cut
