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

package cloud::cisco::webex::restapi::custom::api;

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
            'client-id:s'            => { name => 'client_id' },
            'client-secret:s'        => { name => 'client_secret' },
            'refresh-token:s'        => { name => 'refresh_token' },
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port', default => 443 },
            'proto:s'                => { name => 'proto', default => 'https' },
            'timeout:s'              => { name => 'timeout', default => 30 },
            'unknown-http-status:s'  => {
                name    => 'unknown_http_status',
                default => '%{http_code} < 200 or %{http_code} >= 300'
            },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' },
            'cache-use'              => { name => 'cache_use' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'Webex API OPTIONS', once => 1);

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

    if (centreon::plugins::misc::is_empty($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }

    if (centreon::plugins::misc::is_empty($self->{option_results}->{client_id})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --client-id option.');
        $self->{output}->option_exit();
    }

    if (centreon::plugins::misc::is_empty($self->{option_results}->{client_secret})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --client-secret option.');
        $self->{output}->option_exit();
    }

    if (centreon::plugins::misc::is_empty($self->{option_results}->{refresh_token})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --refresh-token option.');
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
    $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port};
}

sub get_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile =>
        'cisco_webexapi_' . md5_hex($self->{option_results}->{client_id}));
    my $access_token = $self->{cache}->get(name => 'access_token');
    my $expires_on = $self->{cache}->get(name => 'expires_on');

    if ($has_cache_file == 0 || !defined($access_token) || $access_token eq '' || (($expires_on - time()) < 60)) {
        my $post_data = 'client_id=' . $self->{option_results}->{client_id} .
            '&client_secret=' . $self->{option_results}->{client_secret} .
            '&refresh_token=' . $self->{option_results}->{refresh_token} .
            '&grant_type=refresh_token';

        my $content = $self->{http}->request(
            method          => 'POST',
            url_path        => '/v1/access_token',
            query_form_post => $post_data,
            unknown_status  => $self->{option_results}->{unknown_http_status},
            warning_status  => $self->{option_results}->{warning_http_status},
            critical_status => $self->{option_results}->{critical_http_status}
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "An error occurred while decoding the response ('$content').");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $data = {
            updated      => time(),
            access_token => $decoded->{access_token},
            expires_in   => $decoded->{expires_in},
            expires_on   => time() + $decoded->{expires_in}
        };
        $self->{cache}->write(data => $data);
    }

    return $access_token;
}

sub clean_token {
    my ($self, %options) = @_;

    my $data = { updated => time() };
    $self->{cache}->write(data => $data);
}

sub request_api {
    my ($self, %options) = @_;

    my $get_param = [];
    if (defined($options{get_param})) {
        $get_param = $options{get_param};
    }

    my $token = $self->get_token();

    while (1) {
        my ($content) = $self->{http}->request(
            url_path        => $options{endpoint},
            get_param       => $get_param,
            header          => [ 'Authorization: Bearer ' . $token ],
            unknown_status  => '',
            warning_status  => '',
            critical_status => ''
        );

        my $code = $self->{http}->get_code();

        if ($code == 429) {
            my ($retry) = $self->{http}->get_header(name => 'Retry-After');
            $retry = defined($retry) && $retry =~ /^\s*(\d+)\s*/ ? $retry : 1;
            sleep($retry);
            next;
        }

        # Maybe token is invalid. so we retry
        if (!defined($token) || $code < 200 || $code >= 300) {
            $self->clean_token();
            $token = $self->get_token();

            $content = $self->{http}->request(
                url_path        => $options{endpoint},
                get_param       => $get_param,
                header          => [ 'Authorization: Bearer ' . $token ],
                unknown_status  => $self->{unknown_http_status},
                warning_status  => $self->{warning_http_status},
                critical_status => $self->{critical_http_status}
            );
        }

        if (!defined($content) || $content eq '') {
            $self->{output}->add_option_msg(short_msg =>
                "API returns empty content [code: '" . $code . "'] [message: '" . $self->{http}->get_message() . "']");
            $self->{output}->option_exit();
        }

        my $decoded;
        eval {
            $decoded = JSON::XS->new->allow_nonref(1)->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg =>
                "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }

        return $decoded;
    }
}

sub write_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(
        statefile => 'cache_webexapi_' . md5_hex($self->{option_results}->{client_id})
    );
    $self->{cache}->write(data => {
        update_time => time(),
        response    => $self->{data}
    });
}

sub get_cache_file_response {
    my ($self, %options) = @_;

    my $cache_filename = 'cache_webexapi_' . md5_hex($self->{option_results}->{client_id});

    $self->{cache}->read(
        statefile => $cache_filename
    );
    $self->{data} = $self->{cache}->get(name => 'response');
    if (!defined($self->{data})) {
        $self->{output}->add_option_msg(short_msg => 'Cache file missing or could not load ' . $cache_filename);
        $self->{output}->option_exit();
    }

    return $self->{data};
}

sub cache_data {
    my ($self, %options) = @_;

    $self->{data}->{devices} = $self->get_devices();
    $self->{data}->{workspaces} = $self->get_workspaces();
    $self->write_cache_file();
}

sub get_devices {
    my ($self, %options) = @_;

    return $self->get_cache_file_response()->{devices} if (defined($self->{option_results}->{cache_use}));
    return $self->get_devices_from_api();
}

sub get_workspaces {
    my ($self, %options) = @_;

    return $self->get_cache_file_response()->{workspaces} if (defined($self->{option_results}->{cache_use}));
    return $self->get_workspaces_from_api();
}

sub get_devices_from_api {
    my ($self, %options) = @_;
    my $data = [];

    my $start = 0;
    my $max = 100;

    # gets the first 100 devices
    my $paged_items = $self->get_max_devices(start => $start, max => $max);
    push @$data, @{$paged_items};
    my $item_cnt = scalar(@{$paged_items});
    # gets the next 100 devices until there are no more devices left in the response
    while ($item_cnt > 0) {
        $start += 100;
        $paged_items = $self->get_max_devices(start => $start, max => $max);
        $item_cnt = scalar(@{$paged_items});
        push @$data, @{$paged_items};
    }

    return $data;
}

sub get_max_devices {
    my ($self, %options) = @_;

    my $params = {
        endpoint  => '/v1/devices',
        get_param => [ 'start=' . $options{start}, 'max=' . $options{max} ]
    };

    if (defined($self->{option_results}->{resource_type}) && $self->{option_results}->{resource_type} eq 'workspace' && defined $self->{option_results}->{workspace_id}) {
        push @{$params->{get_param}},
            'workspaceId=' . $self->{option_results}->{workspace_id};
    }

    if (defined($self->{option_results}->{resource_type}) && $self->{option_results}->{resource_type} eq 'person' && defined $self->{option_results}->{person_id}) {
        push @{$params->{get_param}},
            'personId=' . $self->{option_results}->{person_id};
    }

    my $response = $self->request_api(%$params);
    my $results = [];

    for my $item (@{$response->{items}}) {
        push @$results, {
            id                  => $item->{id},
            display_name        => $item->{displayName},
            product             => $item->{product},
            ip                  => defined($item->{ip}) ? $item->{ip} : '',
            type                => $item->{type},
            serial              => defined($item->{serial}) && $item->{serial} ?
                $item->{serial} :
                ($self->{option_results}->{use_id_empty_serial} ? 'id:' . substr($item->{id}, -10) : ''),
            lifecycle           => $item->{lifecycle},
            planned_maintenance => $item->{plannedMaintenance},
            connection_status   => $item->{connectionStatus},
            error_codes         => defined($item->{errorCodes}) ? join(';', @{$item->{errorCodes}}) : ''
        };
    }

    return $results;
}

sub get_device {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        my $cached_devices = $self->get_cache_file_response()->{devices};

        foreach my $cached_device (@$cached_devices) {
            if ($cached_device->{id} eq $self->{option_results}->{device_id}) {
                my $device = {};
                $device->{$cached_device->{id}} = $cached_device;
                return $device;
            }
        }
    }

    return $self->get_device_from_api();
}

sub get_device_from_api {
    my ($self, %options) = @_;

    my $params = {
        endpoint => "/v1/devices/$self->{option_results}->{device_id}"
    };

    my $response = $self->request_api(%$params);
    my $device = {};

    $device->{$response->{id}} = {
        display_name        => $response->{displayName},
        product             => $response->{product},
        ip                  => defined($response->{ip}) ? $response->{ip} : '',
        type                => $response->{type},
        serial              => $response->{serial},
        lifecycle           => $response->{lifecycle},
        connection_status   => $response->{connectionStatus},
        planned_maintenance => $response->{plannedMaintenance},
        error_codes         => defined($response->{errorCodes}) ? join(';', @{$response->{errorCodes}}) : ''
    };

    return $device;
}

sub get_workspace {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{cache_use})) {
        my $cached_workspaces = $self->get_cache_file_response()->{workspaces};

        foreach my $cached_workspace (@$cached_workspaces) {
            if ($cached_workspace->{id} eq $self->{option_results}->{workspace_id}) {
                my $workspace = {};
                $workspace->{$cached_workspace->{id}} = $cached_workspace;
                return $workspace;
            }
        }
    }

    return $self->get_workspace_from_api();
}

sub get_workspace_from_api {
    my ($self, %options) = @_;

    my $params = {
        endpoint => "/v1/workspaces/$self->{option_results}->{workspace_id}"
    };

    my $response = $self->request_api(%$params);
    my $workspace = {};

    $workspace->{$response->{id}} = {
        display_name        => $response->{displayName},
        type                => $response->{type},
        planned_maintenance => $response->{plannedMaintenance}->{mode},
        health              => $response->{health}->{level},
    };

    return $workspace;
}

sub get_workspaces_from_api {
    my ($self, %options) = @_;
    my $data = [];

    my $start = 0;
    my $max = 100;

    # gets the first 100 workspaces
    my $paged_items = $self->get_max_workspaces(start => $start, max => $max);
    push @$data, @{$paged_items};
    my $item_cnt = scalar(@{$paged_items});
    # gets the next 100 workspaces until there are no more workspaces left in the response
    while ($item_cnt > 0) {
        $start += 100;
        $paged_items = $self->get_max_workspaces(start => $start, max => $max);
        $item_cnt = scalar(@{$paged_items});
        push @$data, @{$paged_items};
    }

    return $data;
}

sub get_max_workspaces {
    my ($self, %options) = @_;

    my $params = {
        endpoint  => '/v1/workspaces',
        get_param => [ 'start=' . $options{start}, 'max=' . $options{max} ]
    };

    if ($self->{option_results}->{type}) {
        push @{$params->{get_param}}, 'type=' . $self->{option_results}->{type};
    }

    my $response = $self->request_api(%$params);
    my $results = [];

    for my $item (@{$response->{items}}) {
        push @$results, {
            id                    => $item->{id},
            display_name          => $item->{displayName},
            type                  => $item->{type},
            workspace_location_id => $item->{workspaceLocationId}
        };
    }

    return $results;
}

sub get_workspace_locations_from_api {
    my ($self, %options) = @_;

    my $params = {
        endpoint => '/v1/workspaceLocations'
    };

    my $response = $self->request_api(%$params);
    my $results = [];

    for my $item (@{$response->{items}}) {
        push @$results, {
            id           => $item->{id},
            display_name => $item->{displayName},
            address      => $item->{address},
            city         => $item->{cityName},
            latitude     => $item->{latitude},
            longitude    => $item->{longitude}
        };
    }

    return $results;
}

1;

__END__

=head1 NAME

Cisco Webex REST API

=head1 Webex API OPTIONS

Webex REST API

=over 8

=item B<--hostname>

Address of the server that hosts the API.

=item B<--port>

Define the TCP port to use to reach the API (default: 443).

=item B<--proto>

Define the protocol to reach the API (default: 'https').

=item B<--client-id>

Define the client-id for authentication.

=item B<--client-secret>

Define the secret associated with the username.

=item B<--refresh-token>

Define the refresh token associated with the username. Used to renew the access token

=item B<--timeout>

Define the timeout in seconds for HTTP requests (default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
