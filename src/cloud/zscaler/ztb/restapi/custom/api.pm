#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::zscaler::ztb::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw/json_decode is_empty/;
use centreon::plugins::constants qw(:messages);
use Digest::SHA qw(sha256_hex);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless $options{options};
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'client-id:s'            => { name => 'client_id',      default => '' },
            'client-secret:s'        => { name => 'client_secret',  default => '' },
            'login-domain:s'         => { name => 'login_domain',   default => '' },
            'api-domain:s'           => { name => 'api_domain',     default => '' },
            'port:s'                 => { name => 'port',           default => 443 },
            'proto:s'                => { name => 'proto',          default => 'https' },
            'timeout:s'              => { name => 'timeout',        default => 50 },
            'api-path:s'             => { name => 'api_path',       default => '/api' },
            'unknown-http-status:s'  => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' },
            'cache-use'              => { name => 'cache_use' },
            'cache-lifetime:s'       => { name => 'cache_lifetime', default => 1800 }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache_connect} = centreon::plugins::statefile->new(%options);
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

    $self->{$_} = $self->{option_results}->{$_} foreach qw/login_domain api_domain api_path unknown_http_status warning_http_status critical_http_status client_id client_secret cache_lifetime/;

    $self->{output}->option_exit(short_msg => "Need to specify --login-domain option.")
        if ($self->{option_results}->{login_domain} eq '');
    $self->{login_domain} .= '.zslogin.net'
        if ($self->{login_domain} !~ /\./);
    
    $self->{output}->option_exit(short_msg => "Need to specify --api-domain option.")
        if ($self->{option_results}->{api_domain} eq '');
    $self->{api_domain} .= '-api.goairgap.com'
        if ($self->{api_domain} !~ /\./);

    $self->{output}->option_exit(short_msg => "Need to specify --client-id option.")
        if ($self->{client_id} eq '');
    $self->{output}->option_exit(short_msg => "Need to specify --client-secret option.")
        if ($self->{client_secret} eq '');

    $self->{cache_connect}->check_options(option_results => $self->{option_results});
    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{api_domain} . $self->{client_id};
}

sub settings {
    my ($self, %options) = @_;

    return if $self->{settings_done};
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub clean_access_token {
    my ($self, %options) = @_;

    my $datas = { updated => time() };
    $self->{cache_connect}->write(data => $datas);
}

sub get_access_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache_connect}->read(statefile => 'zscaler_ztb_' . sha256_hex($self->get_connection_info()));
    my $token = $self->{cache_connect}->get(name => 'token');
    my $sha_secret_cache = $self->{cache_connect}->get(name => 'sha_secret');
    my $sha_secret = sha256_hex($self->{client_id} . $self->{client_secret});

    if ($has_cache_file == 0 ||
        !defined($token) ||
        (defined($sha_secret_cache) && $sha_secret_cache ne $sha_secret)
        ) {
        my $content = $self->{http}->request(
            method => 'POST',
            hostname => $self->{login_domain},
            url_path => '/oauth2/v1/token',
            post_param => [
                'grant_type=client_credentials',
                'client_id=' . $self->{client_id},
                'client_secret=' . $self->{client_secret},
                'audience=https://api.zscaler.com'
            ],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );

        my $decoded = json_decode($content, output => $self->{output});

        $self->{output}->option_exit(short_msg => "Cannot find access token")
            unless ref $decoded eq 'HASH' && $decoded->{access_token};

        $token = $decoded->{access_token};

        my $datas = {
            updated => time(),
            token => $token,
            sha_secret => $sha_secret
        };

        $self->{cache_connect}->write(data => $datas);
    }

    return $token;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $token = $self->get_access_token();
    my ($content) = $self->{http}->request(
        hostname => $self->{api_domain},
        url_path => $self->{api_path} . $options{endpoint},
        get_param => $options{get_param},
        header => [
            'Accept: application/json',
            'Authorization: Bearer ' . $token
        ],
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    return $content
        if (defined($options{forceReturn}) && defined($options{forceReturn}->{ $self->{http}->get_code() }));

    # Maybe token is invalid. so we retry
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        $self->clean_access_token();
        $token = $self->get_access_token();
        $content = $self->{http}->request(
            hostname => $self->{api_domain},
            url_path => $self->{api_path} . $options{endpoint},
            get_param => $options{get_param},
            header => [
                'Accept: application/json',
                'Authorization: Bearer ' . $token
            ],
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    $self->{output}->option_exit(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($content);

    my $decoded = json_decode($content, output => $self->{output}, no_exit => 1);
    $self->{output}->option_exit(short_msg => MSG_JSON_DECODE_ERROR)
        unless $decoded;

    return $decoded;
}

sub write_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_zscaler_ztb_' . $options{statefile} . '_' . sha256_hex($self->get_connection_info()));
    $self->{cache}->write(data => {
        update_time => time(),
        response => $options{response}
    });
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'cache_zscaler_ztb_' . $options{statefile} . '_' . sha256_hex($self->get_connection_info()));
    my $response = $self->{cache}->get(name => 'response');
    $self->{output}->option_exit(short_msg => 'Cache file missing')
        unless $response;

    my $update_time = $self->{cache}->get(name => 'update_time');
    $self->{output}->option_exit(short_msg => 'Cache file expired')
        if (time() - $self->{cache_lifetime}) > $update_time;

    return $response;
}

sub cache_sites {
    my ($self, %options) = @_;

    my $response = $self->get_sites(disable_cache => 1);
    $self->write_cache_file(
        statefile => 'sites',
        response => $response
    );

    return $response;
}

sub cache_gateways {
    my ($self, %options) = @_;

    my $response = $self->get_gateways(disable_cache => 1);
    $self->write_cache_file(
        statefile => 'gateways',
        response => $response
    );

    return $response;
}

sub cache_gateway_resource {
    my ($self, %options) = @_;

    my $response = $self->get_gateway_resource(disable_cache => 1, gateway_id => $options{gateway_id});
    $self->write_cache_file(
        statefile => 'gateway_resource_' . $options{gateway_id},
        response => $response
    );

    return $response;
}

sub cache_gateway_interfaces {
    my ($self, %options) = @_;

    my $response = $self->get_gateway_interfaces(disable_cache => 1, gateway_id => $options{gateway_id});
    $self->write_cache_file(
        statefile => 'gateway_interfaces_' . $options{gateway_id},
        response => $response
    );

    return $response;
}

sub get_sites {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'sites')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    my $data = $self->request_api(
        endpoint => '/v2/Site/'
    );

    my $response = [];
    foreach (@{$data->{result}->{rows}}) {
        push @$response, {
            id => $_->{id},
            name => $_->{name},
            site_status => $_->{site_status}
        };
    }

    return $response;
}

sub get_gateways {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'gateways')
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    my $data = $self->request_api(
        endpoint => '/v3/Gateway/'
    );
    my $response = [];
    foreach my $site (@{$data->{rows}}) {
        my $item = {
            site_id => $site->{cluster_info}->{site_id},
            site_name => $site->{location},
            cluster_id => $site->{cluster_info}->{cluster_id},
            cluster_name => $site->{cluster_info}->{cluster_name},
        };
        foreach my $gateway (@{$site->{gateways}}) {
            my $gw = { %$item };
            $gw->{gw_id} = $gateway->{gateway_id};
            $gw->{gw_name} = $gateway->{gateway_name};
            $gw->{gw_display_name} = $gateway->{display_name};
            $gw->{gw_ip_address} = $gateway->{gateway_ip_address};
            $gw->{gw_health_color} = $gateway->{health_color};
            $gw->{gw_vrrp_state} = $gateway->{vrrp_state};
            $gw->{gw_desired_state} = $gateway->{desired_state};
            $gw->{gw_operational_state} = $gateway->{operational_state};
            push @$response, $gw;
        }
    }

    return $response;
}

sub get_gateway_resource {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'gateway_resource_' . $options{gateway_id})
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    # in some case, you have 400 return with message: 'sql: no rows in result set'
    my $data = $self->request_api(
        endpoint => '/v3/debug-manager/resource-status',
        get_param => ['gateway_id=' . $options{gateway_id}],
        forceReturn => { 400 => 1 }
    );

    my $response = {};
    if (ref($data) eq 'HASH') {
        $response = {
            container_stats => $data->{containers_stats}->{container_stats},
            system_stats => $data->{system_stats},
            hourly_stat_last => $data->{average_values}->{hourly_stats}->[0],
            uptime => $data->{device_uptime},
            wanmon_avg_values_last => $data->{wanmon_avg_values}->[0]
        };
    }

    return $response;
}

sub get_gateway_interfaces {
    my ($self, %options) = @_;

    return $self->get_cache_file_response(statefile => 'gateway_interfaces_' . $options{gateway_id})
        if $self->{option_results}->{cache_use} && !$options{disable_cache};

    # in some case, you have 400 return with message: 'sql: no rows in result set'
    my $data = $self->request_api(
        endpoint => '/v2/Gateway/interfaces',
        get_param => ['gatewayId=' . $options{gateway_id}],
        forceReturn => { 400 => 1 }
    );

    my $response = [];
    if (ref($data) eq 'ARRAY') {
        foreach my $item (@$data) {
            foreach my $int (@{$item->{interfaces}}) {
                push @$response, {
                    name => $int->{name},
                    description => $int->{description},
                    admin_state => $int->{admin_state},
                    operational_state => $int->{operational_state},
                    if_stats => $int->{if_stats}
                };
            }
        }
    }

    return $response;
}

sub get_cluster_ipsec_status {
    my ($self, %options) = @_;

    my $data = $self->request_api(
        endpoint => '/v2/cluster/ipsec-status',
        get_param => ['cluster_id=' . $options{cluster_id}],
    );

    return $data->{tun_status};
}

sub get_appconnector_config {
    my ($self, %options) = @_;

    my $data = $self->request_api(
        endpoint => '/v3/appconnector/config',
        get_param => ['cluster_id=' . $options{cluster_id}],
    );

    return $data->{result};
}

1;

__END__

=head1 NAME

ZTB Rest API

=head1 REST API OPTIONS

Zero Trust Branch Rest API

=over 8

=item B<--login-domain>

Define the domain for OAuth2 authentification (e.g.: 'test.zslogin.net')

=item B<--api-domain>

Define the domain for ZTB API (e.g.: 'totalenergies-api.goairgap.com')

=item B<--client-id>

Define client ID.

=item B<--client-secret>

Define client secret.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Define https if needed (default: 'https')

=item B<--timeout>

Set timeout in seconds (default: 50).

=item B<--cache-use>

Use the cache file (created with cache mode). 

=item B<--cache-lifetime>

Define the cache lifetime before raising an error (default: 1800 seconds).

=back

=head1 DESCRIPTION

B<custom>.

=cut
