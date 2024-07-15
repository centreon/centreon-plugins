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

package network::cisco::meraki::cloudcontroller::restapi::custom::api;

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
        $options{options}->add_options(arguments =>  {
            'hostname:s'                => { name => 'hostname' },
            'port:s'                    => { name => 'port' },
            'proto:s'                   => { name => 'proto' },
            'api-token:s'               => { name => 'api_token' },
            'timeout:s'                 => { name => 'timeout' },
            'reload-cache-time:s'       => { name => 'reload_cache_time' },
            'ignore-permission-errors'  => { name => 'ignore_permission_errors' },
            'ignore-orgs-api-disabled'  => { name => 'ignore_orgs_api_disabled' },
            'api-filter-orgs:s'         => { name => 'api_filter_orgs' },
            'timespan:s'                => { name => 'timespan' },
            'cache-use'                 => { name => 'cache_use' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    $self->{datas} = {
        uplink_statuses => {},
        uplinks_loss_latency => {}
    };
    $self->{devices_connection_stats} = {};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : 'api.meraki.com';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{api_token} = (defined($self->{option_results}->{api_token})) ? $self->{option_results}->{api_token} : '';
    $self->{reload_cache_time} = (defined($self->{option_results}->{reload_cache_time})) ? $self->{option_results}->{reload_cache_time} : 180;
    $self->{reload_extra_cache_time} = (defined($self->{option_results}->{reload_extra_cache_time})) ? $self->{option_results}->{reload_extra_cache_time} : 10;
    $self->{ignore_permission_errors} = (defined($self->{option_results}->{ignore_permission_errors})) ? 1 : 0;
    $self->{ignore_orgs_api_disabled} = (defined($self->{option_results}->{ignore_orgs_api_disabled})) ? 1 : 0;
    $self->{timespan} = (defined($self->{option_results}->{timespan})) ? $self->{option_results}->{timespan} : 300;

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{api_token} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-token option.");
        $self->{output}->option_exit();
    }

    # we force to use storable module
    $self->{option_results}->{statefile_storable} = 1;
    $self->{cache}->check_options(option_results => $self->{option_results});
    return 0;
}

sub get_token {
    my ($self, %options) = @_;

    return md5_hex($self->{api_token});
}

sub get_shard_hostname {
    my ($self, %options) = @_;

    my $organization_id = $options{organization_id};
    my $network_id = $options{network_id};
    if (defined($options{serial}) && defined($self->{datas}->{devices}->{ $options{serial} })) {
        $network_id = $self->{datas}->{devices}->{ $options{serial} }->{networkId};
    }
    if (defined($network_id) && defined($self->{datas}->{networks}->{$network_id})) {
        $organization_id = $self->{datas}->{networks}->{$network_id}->{organizationId};
    }

    if (defined($organization_id)) {
        if (defined($self->{datas}->{orgs}->{$organization_id})
            && $self->{datas}->{orgs}->{$organization_id}->{url} =~ /^(?:http|https):\/\/(.*?)\//) {
            return $1;
        }
    }

    return undef;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{http}->add_header(key => 'X-Cisco-Meraki-API-Key', value => $self->{api_token});
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    my $hostname = $self->{hostname};
    if (defined($options{hostname})) {
        $hostname = $options{hostname};
    }

    #400: Bad Request- You did something wrong, for example a malformed request or missing parameter.
    #403: Forbidden- You don't have permission to do that.
    #404: Not found- No such URL, or you don't have access to the API or organization at all. 
    #429: Too Many Requests- You submitted more than 5 calls in 1 second to an Organization, triggering rate limiting. This also applies for API calls made across multiple organizations that triggers rate limiting for one of the organizations.
    my $results = [];
    my $full_url;
    my $get_param = defined($options{get_param}) ? $options{get_param} : [];
    if (defined($options{paginate})) {
        push @$get_param, 'perPage=' . $options{paginate};
    }
    while (1) {
        my $response =  $self->{http}->request(
            full_url => $full_url,
            hostname => $hostname,
            url_path => '/api/v1' . $options{endpoint},
            get_param => $get_param,
            critical_status => '',
            warning_status => '',
            unknown_status => ''
        );

        my $code = $self->{http}->get_code();

        return [] if ($code == 403 && $self->{ignore_permission_errors} == 1);
        return undef if (defined($options{ignore_codes}) && defined($options{ignore_codes}->{$code}));

        if ($code == 429) {
            my ($retry) = $self->{http}->get_header(name => 'Retry-After');
            $retry = defined($retry) && $retry =~ /^\s*(\d+)\s*/ ? $retry : 1; 
            sleep($retry);
            next;
        }

        if ($code < 200 || $code >= 300) {
            $self->{output}->add_option_msg(short_msg => $code . ' ' . $self->{http}->get_message());
            $self->{output}->option_exit();
        }

        my $content;
        eval {
            $content = JSON::XS->new->utf8->allow_nonref(1)->decode($response);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
            $self->{output}->option_exit();
        }

        if (defined($options{paginate})) {
            push @$results, @$content;

            my ($link) = $self->{http}->get_header(name => 'Link');
            return $results if (!defined($link) || $link !~ /,\s+<([^;]*?)>;\s+rel=next/);

            $get_param = undef;
            $full_url = $1;
            next;
        }

        return ($content);
    }
}

sub write_cache_file {
    my ($self, %options) = @_;

    $self->{cache}->read(
        statefile => 'cache_meraki_' . md5_hex(
            $self->{api_token} . '_' . 
            (defined($self->{option_results}->{api_filter_orgs}) ? $self->{option_results}->{api_filter_orgs} : '')
        )
    );
    $self->{cache}->write(data => {
        update_time => time(),
        response => $self->{datas}
    });
}

sub get_cache_file_response {
    my ($self, %options) = @_;
    my $cache_filename = 'cache_meraki_'
                         . md5_hex($self->{api_token} . '_' .(defined($self->{option_results}->{api_filter_orgs}) ?
                                                              $self->{option_results}->{api_filter_orgs} : '')
                                  );

    $self->{cache}->read(
        statefile => $cache_filename
    );
    $self->{datas} = $self->{cache}->get(name => 'response');
    if (!defined($self->{datas})) {
        $self->{output}->add_option_msg(short_msg => 'Cache file missing or could not load ' . $cache_filename);
        $self->{output}->option_exit();
    }

    return $self->{datas};
}

sub call_datas {
    my ($self, %options) = @_;

    $self->get_organizations();
    if (!defined($options{skipNetworks})) {
        $self->get_networks(orgs => [keys %{$self->{datas}->{orgs}}]);
    }

    if (!defined($options{skipDevices})) {
        $self->get_devices(orgs => [keys %{$self->{datas}->{orgs}}]);
    }
    if (!defined($options{skipDevicesStatus})) {
        $self->get_organization_device_statuses(orgs => [keys %{$self->{datas}->{orgs}}]);
    }
    if (!defined($options{skipVpnTunnelsStatus})) {
        $self->get_organization_vpn_tunnels_statuses(orgs => [keys %{$self->{datas}->{orgs}}]);
    }

    if (defined($options{cache})) {
        foreach my $orgId (keys %{$self->{datas}->{orgs}}) {
            $self->get_network_device_uplink(orgId => $orgId);
        }
        foreach my $orgId (keys %{$self->{datas}->{orgs}}) {
            $self->get_organization_uplink_loss_and_latency(orgId => $orgId);
        }
    }
}

sub cache_datas {
    my ($self, %options) = @_;

    $self->call_datas(cache => 1);
    $self->write_cache_file();

    return $self->{datas};
}

sub get_datas {
    my ($self, %options) = @_;

    return $self->get_cache_file_response() if (defined($self->{option_results}->{cache_use}));
    $self->call_datas(%options);
    return $self->{datas};
}

sub get_organizations {
    my ($self, %options) = @_;

    my $datas = $self->request_api(endpoint => '/organizations');
    $self->{datas}->{orgs} = {};
    if (defined($datas)) {
        foreach (@$datas) {
            next if (defined($self->{option_results}->{api_filter_orgs}) && $self->{option_results}->{api_filter_orgs} ne '' &&
                $_->{name} !~ /$self->{option_results}->{api_filter_orgs}/);

            $self->{datas}->{orgs}->{ $_->{id} } = {
                name => $_->{name},
                url => $_->{url}
            };
        }
    }

    return $self->{datas}->{orgs};
}

sub get_networks {
    my ($self, %options) = @_;

    my $ignore_codes = {};
    $ignore_codes = { 404 => 1 } if ($self->{ignore_orgs_api_disabled} == 1);

    $self->{datas}->{networks} = {};
    foreach my $id (@{$options{orgs}}) {
        my $datas = $self->request_api(
            endpoint => '/organizations/' . $id . '/networks',
            hostname => $self->get_shard_hostname(organization_id => $id),
            ignore_codes => $ignore_codes
        );

        if (!defined($datas) && $self->{ignore_orgs_api_disabled} == 1) {
            delete $self->{datas}->{orgs}->{$id};
            next;
        }

        if (defined($datas)) {
            foreach (@$datas) {
                if (defined($options{extended})) {
                    $self->{datas}->{networks}->{ $_->{id} } = $_;
                }  else {
                    $self->{datas}->{networks}->{ $_->{id} } = {
                        name => $_->{name},
                        organizationId => $_->{organizationId}
                    };
                }
            }
        }
    }

    return $self->{datas}->{networks};
}

sub get_devices {
    my ($self, %options) = @_;

    $self->{datas}->{devices} = {};
    foreach my $id (@{$options{orgs}}) {
        my $datas = $self->request_api(
            endpoint => '/organizations/' . $id . '/devices',
            paginate => 1000, 
            hostname => $self->get_shard_hostname(organization_id => $id)
        );
        if (defined($datas)) {
             foreach (@$datas) {
                if (defined($options{extended})) {
                    $self->{datas}->{devices}->{ $_->{serial} } = $_;
                    $self->{datas}->{devices}->{ $_->{serial} }->{orgId} = $id;
                } else {
                    $self->{datas}->{devices}->{ $_->{serial} } = {
                        name => $_->{name},
                        networkId => $_->{networkId},
                        orgId => $id,
                        tags => $_->{tags},
                        model => $_->{model}
                    };
                }
            }
        }
    }

    return $self->{datas}->{devices};
}

sub get_organization_device_statuses {
    my ($self, %options) = @_;

    $self->{datas}->{devices_status} =  {};
    foreach my $id (@{$options{orgs}}) {
        my $datas = $self->request_api(
            endpoint => '/organizations/' . $id . '/devices/statuses',
            paginate => 1000,
            hostname => $self->get_shard_hostname(organization_id => $id)
        );
        foreach (@$datas) {
            if (defined($options{extended})) {
                $self->{datas}->{devices_status}->{ $_->{serial} } = $_;
            } else {
                $self->{datas}->{devices_status}->{ $_->{serial} } = {
                    status => $_->{status}
                };
            }
        }
    }

    return $self->{datas}->{devices_status};
}

sub get_organization_vpn_tunnels_statuses {
    my ($self, %options) = @_;

    $self->{datas}->{vpn_tunnels_status} =  {};
    foreach my $id (@{$options{orgs}}) {
        my $datas = $self->request_api(
            endpoint => '/organizations/' . $id . '/appliance/vpn/statuses',
            paginate => 300,
            hostname => $self->get_shard_hostname(organization_id => $id),
            ignore_codes => { 400 => 1 } # it can be disabled
        );
        foreach (@$datas) {
            $self->{datas}->{vpn_tunnels_status}->{ $_->{deviceSerial} } = $_;
            $self->{datas}->{vpn_tunnels_status}->{ $_->{deviceSerial} }->{organizationId} = $id;
        }
    }

    return $self->{datas}->{vpn_tunnels_status};
}

sub get_network_device_uplink {
    my ($self, %options) = @_;

    if (!defined($self->{datas}->{uplink_statuses}->{ $options{orgId} })) {
        $self->{datas}->{uplink_statuses}->{ $options{orgId} } = {};
        my $datas = $self->request_api(
            endpoint => '/organizations/' . $options{orgId} . '/uplinks/statuses',
            paginate => 1000,
            hostname => $self->get_shard_hostname(organization_id => $options{orgId})
        );
        foreach (@$datas) {
            $self->{datas}->{uplink_statuses}->{ $options{orgId} }->{ $_->{serial} } = $_->{uplinks};
        }
    }

    return defined($options{serial}) ?
        $self->{datas}->{uplink_statuses}->{ $options{orgId} }->{ $options{serial} } :
        $self->{datas}->{uplink_statuses}->{ $options{orgId} };
}

sub get_organization_uplink_loss_and_latency {
    my ($self, %options) = @_;

    if (!defined($self->{datas}->{uplinks_loss_latency}->{ $options{orgId} })) {
        $self->{datas}->{uplinks_loss_latency}->{ $options{orgId} } = {};
        my $datas = $self->request_api(
            endpoint => '/organizations/' . $options{orgId} . '/devices/uplinksLossAndLatency',
            get_param => [ 'timespan=' . $self->{timespan} ],
            paginate => 1000,
            hostname => $self->get_shard_hostname(organization_id => $options{orgId}),
            ignore_codes => { 404 => 1 }
        );

        if (defined($datas)) {
            foreach (@$datas) {
                # sometimes uplink is undef. so we skip
                next if (!defined($_->{uplink}) || !defined($_->{serial}));

                $self->{datas}->{uplinks_loss_latency}->{ $options{orgId} }->{ $_->{serial} } = {}
                    if (!defined($self->{datas}->{uplinks_loss_latency}->{ $options{orgId} }->{ $_->{serial} }));
                $self->{datas}->{uplinks_loss_latency}->{ $options{orgId} }->{ $_->{serial} }->{ $_->{uplink} } = $_;
            }
        }
    }

    return defined($options{serial}) ?
        $self->{datas}->{uplinks_loss_latency}->{ $options{orgId} }->{ $options{serial} } :
        $self->{datas}->{uplinks_loss_latency}->{ $options{orgId} };
}

sub get_device_clients {
    my ($self, %options) = @_;

    return $self->request_api(
        endpoint => '/devices/' . $options{serial} . '/clients',
        get_param => [ 'timespan=' . $self->{timespan} ],
        hostname => $self->get_shard_hostname(serial => $options{serial})
    )
}

sub get_device_switch_port_statuses {
    my ($self, %options) = @_;

    return $self->request_api(
        endpoint => '/devices/' . $options{serial} . '/switch/ports/statuses',
        get_param => [ 'timespan=' . $self->{timespan} ],
        hostname => $self->get_shard_hostname(serial => $options{serial})
    );
}

sub get_network_device_connection_stats {
    my ($self, %options) = @_;

    if (!defined($self->{devices_connection_stats}->{ $options{network_id} })) {
        $self->{devices_connection_stats}->{ $options{network_id} } = {};
        my $datas = $self->request_api(
            endpoint => '/networks/' . $options{network_id} . '/wireless/devices/connectionStats',
            get_param => [ 'timespan=' . $self->{timespan} ],
            hostname => $self->get_shard_hostname(network_id => $options{network_id})
        );
        foreach (@$datas) {
            $self->{devices_connection_stats}->{ $options{network_id} }->{ $_->{serial} } = $_->{connectionStats};
        }
    }

    return defined($options{serial}) ?
        $self->{devices_connection_stats}->{ $options{network_id} }->{ $options{serial} } :
        $self->{devices_connection_stats}->{ $options{network_id} };
}

sub get_network_device_performance {
    my ($self, %options) = @_;

    $self->request_api(
        endpoint => '/devices/' . $options{serial} . '/appliance/performance',
        hostname => $self->get_shard_hostname(network_id => $options{network_id}),
        ignore_codes => { 400 => 1, 204 => 1 }
    );
}

sub get_organization_api_requests_overview {
    my ($self, %options) = @_;
    
    my $results = {};
    foreach my $id (@{$options{orgs}}) {
        $results->{$id} = $self->request_api(
            endpoint => '/organizations/' . $id . '/apiRequests/overview',
            get_param => [ 'timespan=' . $self->{timespan} ],
            hostname => $self->get_shard_hostname(organization_id => $id)
        );
    }

    return $results;
}

sub get_networks_connection_stats {
    my ($self, %options) = @_;

    return $self->request_api(
        endpoint => '/networks/' . $options{network_id},
        hostname => $self->get_shard_hostname(network_id => $options{network_id}),
        ignore_codes => { 400 => 1 }
    );
}

sub get_networks_clients {
    my ($self, %options) = @_;

    return $self->request_api(
        endpoint => '/networks/' . $options{network_id} . '/clients',
        get_param => [ 'timespan=' . $self->{timespan} ],
        hostname => $self->get_shard_hostname(network_id => $options{network_id}),
        ignore_codes => { 400 => 1 }
    );
}

1;

__END__

=head1 NAME

Meraki REST API

=head1 SYNOPSIS

Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Meraki API hostname (default: 'api.meraki.com')

=item B<--port>

Define the TCP port to use to reach the API (default: 443).

=item B<--proto>

Define the protocol to reach the API (default: 'https').

=item B<--api-token>

Meraki API token.

=item B<--timeout>

Define the timeout for HTTP requests.

=item B<--ignore-permission-errors>

Ignore permission errors (403 status code).

=item B<--ignore-orgs-api-disabled>

Ignore organizations where the API is disabled.

=item B<--api-filter-orgs>

Define the organizations to monitor (regular expression).

=item B<--cache-use>

Use the cache file instead of requesting the API (the cache file can be created with the cache mode).

=back

=head1 DESCRIPTION

B<custom>.

=cut
