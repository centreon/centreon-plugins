#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::cisco::meraki::cloudcontroller::restapi::mode::devices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub custom_link_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{link_status};
}

sub custom_port_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{port_status} . ' [enabled: ' . $self->{result_values}->{port_enabled} . ']';
}

sub device_long_output {
    my ($self, %options) = @_;

    return "checking device '" . $options{instance_value}->{display} . "'";
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return "Device '" . $options{instance_value}->{display} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Devices ';
}

sub prefix_connection_output {
    my ($self, %options) = @_;

    return 'connection ';
}

sub prefix_traffic_output {
    my ($self, %options) = @_;

    return 'traffic ';
}

sub prefix_link_output {
    my ($self, %options) = @_;

    return "link '" . $options{instance_value}->{display} . "' ";
}

sub prefix_port_output {
    my ($self, %options) = @_;

    return "port '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output', indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'device_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'device_performance', type => 0, skipped_code => { -10 => 1 } },
                { name => 'device_connections', type => 0, cb_prefix_output => 'prefix_connection_output', skipped_code => { -10 => 1 } },
                { name => 'device_traffic', type => 0, cb_prefix_output => 'prefix_traffic_output', skipped_code => { -10 => 1, -11 => 1 } },
                { name => 'device_links', display_long => 1, cb_prefix_output => 'prefix_link_output',  message_multiple => 'All links are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'device_ports', display_long => 1, cb_prefix_output => 'prefix_port_output',  message_multiple => 'All ports are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-online', nlabel => 'devices.total.online.count', display_ok => 0, set => {
                key_values => [ { name => 'online' }, { name => 'total' } ],
                output_template => 'online: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-offline', nlabel => 'devices.total.offline.count', display_ok => 0, set => {
                key_values => [ { name => 'offline' }, { name => 'total' } ],
                output_template => 'offline: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-alerting', nlabel => 'devices.total.alerting.count', display_ok => 0, set => {
                key_values => [ { name => 'alerting' }, { name => 'total' } ],
                output_template => 'alerting: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
    ];

    $self->{maps_counters}->{device_status} = [
        { label => 'status', type => 2, critical_default => '%{status} =~ /alerting/i', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{device_performance} = [
        { label => 'load', nlabel => 'device.load.count', set => {
                key_values => [ { name => 'perfscore' } ],
                output_template => 'load: %s',
                perfdatas => [
                    { template => '%d', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{device_connections} = [
        { label => 'connections-success', nlabel => 'device.connections.success.count', set => {
                key_values => [ { name => 'assoc' } ],
                output_template => 'success: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'connections-auth', nlabel => 'device.connections.auth.count', display_ok => 0, set => {
                key_values => [ { name => 'auth' } ],
                output_template => 'auth: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'connections-assoc', nlabel => 'device.connections.assoc.count', display_ok => 0, set => {
                key_values => [ { name => 'assoc' } ],
                output_template => 'assoc: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'connections-dhcp', nlabel => 'device.connections.dhcp.count', display_ok => 0, set => {
                key_values => [ { name => 'dhcp' } ],
                output_template => 'dhcp: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'connections-dns', nlabel => 'device.connections.dns.count', display_ok => 0, set => {
                key_values => [ { name => 'dns' } ],
                output_template => 'dns: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{device_traffic} = [
        { label => 'traffic-in', nlabel => 'device.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_template => 'in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'device.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_template => 'out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{device_links} = [
        { label => 'link-status', type => 2, critical_default => '%{link_status} =~ /failed/i', set => {
                key_values => [ { name => 'link_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_link_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'link-latency', nlabel => 'device.link.latency.milliseconds', set => {
                key_values => [ { name => 'latency_ms' } ],
                output_template => 'latency: %.2f ms',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'ms', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'link-loss', nlabel => 'device.link.loss.percentage', set => {
                key_values => [ { name => 'loss_percent' } ],
                output_template => 'loss: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{device_ports} = [
        { label => 'port-status', type => 2, critical_default => '%{port_enabled} == 1 and %{port_status} !~ /^connected/i', set => {
                key_values => [ { name => 'port_status' }, { name => 'port_enabled' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_port_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'port-traffic-in', nlabel => 'device.port.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'port-traffic-out', nlabel => 'device.port.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-device-name:s'         => { name => 'filter_device_name' },
        'filter-network-id:s'          => { name => 'filter_network_id' },
        'filter-organization-name:s'   => { name => 'filter_organization_name' },
        'filter-organization-id:s'     => { name => 'filter_organization_id' },
        'filter-tags:s'                => { name => 'filter_tags' },
        'add-switch-ports'             => { name => 'add_switch_ports' },
        'skip-traffic-disconnect-port' => { name => 'skip_traffic_disconnect_port' }
    });

    return $self;
}

sub add_connection_stats {
    my ($self, %options) = @_;

    my $connections = $options{custom}->get_network_device_connection_stats(
        timespan => $options{timespan},
        serial => $options{serial},
        network_id => $options{network_id}
    );

    $self->{devices}->{ $options{serial} }->{device_connections} = {
        assoc => defined($connections->{assoc}) ? $connections->{assoc} : 0,
        auth => defined($connections->{auth}) ? $connections->{auth} : 0,
        dhcp => defined($connections->{dhcp}) ? $connections->{dhcp} : 0,
        dns => defined($connections->{dns}) ? $connections->{dns} : 0,
        success => defined($connections->{assoc}) ? $connections->{success} : 0
    };
}

sub add_clients {
    my ($self, %options) = @_;

    my $clients = $options{custom}->get_device_clients(
        timespan => $options{timespan},
        serial => $options{serial}
    );

    $self->{devices}->{ $options{serial} }->{device_traffic} = {
        display => $options{name},
        traffic_in => 0,
        traffic_out => 0
    };

    if (defined($clients)) {
        foreach (@$clients) {
            $self->{devices}->{ $options{serial} }->{device_traffic}->{traffic_in} += $_->{usage}->{recv} * 8;
            $self->{devices}->{ $options{serial} }->{device_traffic}->{traffic_out} += $_->{usage}->{sent} * 8;
        }
    }
}

sub add_uplink {
    my ($self, %options) = @_;

    my $links = $options{custom}->get_network_device_uplink(
        serial => $options{serial},
        network_id => $options{network_id}
    );

    if (defined($links)) {
        foreach (@$links) {
            my $interface = lc($_->{interface});
            $interface =~ s/\s+//g;
            $self->{devices}->{ $options{serial} }->{device_links}->{$interface} = {
                display => $interface,
                link_status => lc($_->{status})
            };
        }
    }
}

sub add_uplink_loss_latency {
    my ($self, %options) = @_;

    # 5 minutes max timespan
    my $links = $options{custom}->get_organization_uplink_loss_and_latency(
        timespan => 300,
        serial => $options{serial},
        organization_id => $options{custom}->get_organization_id(network_id => $options{network_id})
    );

    return if (!defined($links));

    foreach (values %$links) {
        my $interface = lc($_->{uplink});
        $interface =~ s/\s+//g;
        next if (!defined($self->{devices}->{ $options{serial} }->{device_links}->{$interface}));

        my ($latency, $loss) = (0, 0);
        foreach my $ts (@{$_->{timeSeries}}) {
            $latency += $ts->{latencyMs};
            $loss += $ts->{lossPercent};
        }

        if (scalar(@{$_->{timeSeries}}) > 0) {
            $latency /= scalar(@{$_->{timeSeries}});
            $loss /= scalar(@{$_->{timeSeries}});
        }

        $self->{devices}->{ $options{serial} }->{device_links}->{$interface}->{loss_percent} = $loss;
        $self->{devices}->{ $options{serial} }->{device_links}->{$interface}->{latency_ms} = $latency;
    }
}

sub add_performance {
    my ($self, %options) = @_;

    my $perf = $options{custom}->get_network_device_performance(
        serial => $options{serial},
        network_id => $options{network_id}
    );

    if (defined($perf) && defined($perf->{perfScore})) {
        $self->{devices}->{ $options{serial} }->{device_performance} = {
            perfscore => $perf->{perfScore}
        };
    }
}

sub add_switch_port_statuses {
    my ($self, %options) = @_;

    my $ports = $options{custom}->get_device_switch_port_statuses(
        timespan => $options{timespan},
        serial => $options{serial}
    );
    foreach (@$ports) {
        $self->{devices}->{ $options{serial} }->{device_ports}->{ $_->{portId} } = {
            display => $_->{portId},
            port_status => lc($_->{status}),
            port_enabled => $_->{enabled} =~ /True|1/i ? 1 : 0
        };
        next if (defined($self->{option_results}->{skip_traffic_disconnect_port}) && $_->{status} =~ /disconnected/i);
        
        $self->{devices}->{ $options{serial} }->{device_ports}->{ $_->{portId} }->{traffic_in} = $_->{usageInKb}->{recv} * 1000 * 8,
        $self->{devices}->{ $options{serial} }->{device_ports}->{ $_->{portId} }->{traffic_out} = $_->{usageInKb}->{sent} * 1000 * 8;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'meraki_' . $self->{mode} . '_' . $options{custom}->get_token()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_device_name}) ? md5_hex($self->{option_results}->{filter_device_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_network_id}) ? md5_hex($self->{option_results}->{filter_network_id}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_organization_id}) ? md5_hex($self->{option_results}->{filter_organization_id}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_organization_name}) ? md5_hex($self->{option_results}->{filter_organization_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_tags}) ? md5_hex($self->{option_results}->{filter_tags}) : md5_hex('all'));
    my $last_timestamp = $self->read_statefile_key(key => 'last_timestamp');
    my $timespan = 300;
    $timespan = time() - $last_timestamp if (defined($last_timestamp));

    my $cache_devices = $options{custom}->get_cache_devices();
    my $devices = {};
    foreach (values %$cache_devices) {
        if (defined($self->{option_results}->{filter_device_name}) && $self->{option_results}->{filter_device_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_device_name}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_network_id}) && $self->{option_results}->{filter_network_id} ne '' &&
            $_->{networkId} !~ /$self->{option_results}->{filter_network_id}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_tags}) && $self->{option_results}->{filter_tags} ne '' &&
            (!defined($_->{tags}) || $_->{tags} !~ /$self->{option_results}->{filter_tags}/)) {
            $self->{output}->output_add(long_msg => "skipping device '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }
        
        my $organization = $options{custom}->get_organization(network_id => $_->{networkId});
        if (defined($self->{option_results}->{filter_organization_id}) && $self->{option_results}->{filter_organization_id} ne '' &&
            $organization->{id} !~ /$self->{option_results}->{filter_organization_id}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_organization_name}) && $self->{option_results}->{filter_organization_name} ne '' &&
            $organization->{name} !~ /$self->{option_results}->{filter_organization_name}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $devices->{ $_->{serial} } = $_->{model};
    }

    my $device_statuses = $options{custom}->get_organization_device_statuses();

    #                   | /clients | /connectionStats | /performance | /uplink | /uplinksLossAndLatency | /switchPortStatuses
    #-------------------|----------|---------------------------------|---------|------------------------|-----------------------
    # MV [camera]       |          |                  |              |    X    |                        |
    # MS [switch]       |    X     |                  |              |    X    |                        |        X
    # MG [cellullar gw] |    X     |         X        |              |    X    |                        |
    # MX [appliance]    |    X     |                  |      X       |    X    |            X           |
    # MR [wireless]     |    X     |         X        |              |    X    |                        |

    $self->{global} = { total => 0, online => 0, offline => 0, alerting => 0 };
    $self->{devices} = {};
    foreach my $serial (keys %$devices) {
        $self->{devices}->{$serial} = {
            display => $cache_devices->{$serial}->{name},
            device_status => {
                display => $cache_devices->{$serial}->{name},
                status => $device_statuses->{$serial}->{status}
            },
            device_links => {},
            device_ports => {}
        };

        if ($devices->{$serial} =~ /^(?:MG|MR)/) {
            $self->add_connection_stats(
                custom => $options{custom},
                timespan => $timespan,
                serial => $serial,
                name => $cache_devices->{$serial}->{name},
                network_id => $cache_devices->{$serial}->{networkId}
            );
        }
        if ($devices->{$serial} =~ /^(?:MS|MG|MR|MX)/) {
            $self->add_clients(
                custom => $options{custom},
                timespan => $timespan,
                serial => $serial,
                name => $cache_devices->{$serial}->{name}
            );
        }
        if ($devices->{$serial} =~ /^(?:MV|MS|MG|MR|MX)/) {
            $self->add_uplink(
                custom => $options{custom},
                serial => $serial,
                name => $cache_devices->{$serial}->{name},
                network_id => $cache_devices->{$serial}->{networkId}
            );
        }
        if (defined($self->{option_results}->{add_switch_ports}) && $devices->{$serial} =~ /^MS/) {
            $self->add_switch_port_statuses(
                custom => $options{custom},
                timespan => $timespan,
                serial => $serial
            );
        }
        if ($devices->{$serial} =~ /^MX/) {
            $self->add_performance(
                custom => $options{custom},
                serial => $serial,
                name => $cache_devices->{$serial}->{name},
                network_id => $cache_devices->{$serial}->{networkId}
            );
            $self->add_uplink_loss_latency(
                custom => $options{custom},
                timespan => $timespan,
                serial => $serial,
                network_id => $cache_devices->{$serial}->{networkId}
            );
        }

        $self->{global}->{total}++;
        $self->{global}->{ lc($device_statuses->{$serial}->{status}) }++
            if (defined($self->{global}->{ lc($device_statuses->{$serial}->{status}) }));
    }

    if (scalar(keys %{$self->{devices}}) <= 0) {
        $self->{output}->output_add(short_msg => 'no devices found');
    }
}

1;

__END__

=head1 MODE

Check devices.

=over 8

=item B<--filter-device-name>

Filter devices by name (Can be a regexp).

=item B<--filter-network-id>

Filter devices by network id (Can be a regexp).

=item B<--filter-organization-id>

Filter devices by organization id (Can be a regexp).

=item B<--filter-organization-name>

Filter devices by organization name (Can be a regexp).

=item B<--filter-tags>

Filter devices by tags (Can be a regexp).

=item B<--add-switch-ports>

Add switch port statuses and traffic.

=item B<--skip-traffic-disconnect-port>

Skip port traffic counters if port status is disconnected.

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /alerting/i').
Can used special variables like: %{status}, %{display}

=item B<--unknown-link-status>

Set unknown threshold for status.
Can used special variables like: %{link_status}, %{display}

=item B<--warning-link-status>

Set warning threshold for status.
Can used special variables like: %{link_status}, %{display}

=item B<--critical-link-status>

Set critical threshold for status (Default: '%{link_status} =~ /failed/i').
Can used special variables like: %{link_status}, %{display}

=item B<--unknown-port-status>

Set unknown threshold for status.
Can used special variables like: %{port_status}, %{port_enabled}, %{display}

=item B<--warning-port-status>

Set warning threshold for status.
Can used special variables like: %{port_status}, %{port_enabled}, %{display}

=item B<--critical-port-status>

Set critical threshold for status (Default: '%{port_enabled} == 1 and %{port_status} !~ /^connected/i').
Can used special variables like: %{port_status}, %{port_enabled}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-online', 'total-offline', 'total-alerting',
'traffic-in', 'traffic-out', 'connections-success', 'connections-auth',
'connections-assoc', 'connections-dhcp', 'connections-dns',
'load', 'link-latency' (ms), ''link-loss' (%),
'port-traffic-in', 'port-traffic-out'.

=back

=cut
