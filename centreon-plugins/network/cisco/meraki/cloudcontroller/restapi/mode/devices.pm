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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub custom_link_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{link_status};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output', indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'device_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'device_connections', type => 0, cb_prefix_output => 'prefix_connection_output', skipped_code => { -10 => 1 } },
                { name => 'device_traffic', type => 0, cb_prefix_output => 'prefix_traffic_output', skipped_code => { -10 => 1, -11 => 1 } },
                { name => 'device_links', display_long => 1, cb_prefix_output => 'prefix_link_output',  message_multiple => 'All links are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-online', nlabel => 'devices.total.online.count', display_ok => 0, set => {
                key_values => [ { name => 'online'}, { name => 'total'} ],
                output_template => 'online: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-offline', nlabel => 'devices.total.offline.count', display_ok => 0, set => {
                key_values => [ { name => 'offline'}, { name => 'total'} ],
                output_template => 'offline: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-alerting', nlabel => 'devices.total.alerting.count', display_ok => 0, set => {
                key_values => [ { name => 'alerting'}, { name => 'total'} ],
                output_template => 'alerting: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
    ];

    $self->{maps_counters}->{device_status} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];

    $self->{maps_counters}->{device_connections} = [
        { label => 'connections-success', nlabel => 'device.connections.success.count', set => {
                key_values => [ { name => 'assoc' }, { name => 'display' } ],
                output_template => 'success: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'connections-auth', nlabel => 'device.connections.auth.count', display_ok => 0, set => {
                key_values => [ { name => 'auth' }, { name => 'display' } ],
                output_template => 'auth: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'connections-assoc', nlabel => 'device.connections.assoc.count', display_ok => 0, set => {
                key_values => [ { name => 'assoc' }, { name => 'display' } ],
                output_template => 'assoc: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'connections-dhcp', nlabel => 'device.connections.dhcp.count', display_ok => 0, set => {
                key_values => [ { name => 'dhcp' }, { name => 'display' } ],
                output_template => 'dhcp: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'connections-dns', nlabel => 'device.connections.dns.count', display_ok => 0, set => {
                key_values => [ { name => 'dns' }, { name => 'display' } ],
                output_template => 'dns: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
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
        { label => 'link-status',  threshold => 0, set => {
                key_values => [ { name => 'link_status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_link_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
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

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-device-name:s'   => { name => 'filter_device_name' },
        'unknown-status:s'       => { name => 'unknown_status', default => '' },
        'warning-status:s'       => { name => 'warning_status', default => '' },
        'critical-status:s'      => { name => 'critical_status', default => '%{status} =~ /alerting/i' },
        'unknown-link-status:s'  => { name => 'unknown_link_status', default => '' },
        'warning-link-status:s'  => { name => 'warning_link_status', default => '' },
        'critical-link-status:s' => { name => 'critical_link_status', default => '%{link_status} =~ /failed/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'unknown_status', 'warning_status', 'critical_status',
        'unknown_link_status', 'warning_link_status', 'critical_link_status'
    ]);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'meraki_' . $self->{mode} . '_' . $options{custom}->get_token()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_device_name}) ? md5_hex($self->{option_results}->{filter_device_name}) : md5_hex('all'));
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

        $devices->{$_->{serial}} = $_->{networkId};
    }

    my $device_statuses = $options{custom}->get_organization_device_statuses();
    my $connections = $options{custom}->get_network_device_connection_stats(timespan => $timespan, devices => $devices);
    my $clients = $options{custom}->get_device_clients(timespan => $timespan, devices => $devices);
    my $links = $options{custom}->get_network_device_uplink(devices => $devices);

    $self->{global} = { total => 0, online => 0, offline => 0, alerting => 0 };
    $self->{devices} = {};
    foreach my $serial (keys %$devices) {
        $self->{devices}->{$serial} = {
            display => $cache_devices->{$serial}->{name},
            device_status => {
                display => $cache_devices->{$serial}->{name},
                status => $device_statuses->{$serial}->{status}
            },
            device_connections => {
                display => $cache_devices->{$serial}->{name},
                assoc => defined($connections->{$serial}->{assoc}) ? $connections->{$serial}->{assoc} : 0,
                auth => defined($connections->{$serial}->{auth}) ? $connections->{$serial}->{auth} : 0,
                dhcp => defined($connections->{$serial}->{dhcp}) ? $connections->{$serial}->{dhcp} : 0,
                dns => defined($connections->{$serial}->{dns}) ? $connections->{$serial}->{dns} : 0,
                success => defined($connections->{$serial}->{assoc}) ? $connections->{$serial}->{success} : 0,
            },
            device_traffic => {
                display => $cache_devices->{$serial}->{name},
                traffic_in => 0,
                traffic_out => 0
            },
            device_links => {}
        };

        if (defined($clients->{$serial})) {
            foreach (@{$clients->{$serial}}) {
                $self->{devices}->{$serial}->{device_traffic}->{traffic_in} += $_->{usage}->{recv} * 8;
                $self->{devices}->{$serial}->{device_traffic}->{traffic_out} += $_->{usage}->{sent} * 8;
            }
        }

        if (defined($links->{$serial})) {
            foreach (@{$links->{$serial}}) {
                $self->{devices}->{$serial}->{device_links}->{$_->{interface}} = {
                    display => $_->{interface},
                    link_status => lc($_->{status})
                };
            }
        }

        $self->{global}->{total}++;
        $self->{global}->{ lc($device_statuses->{$serial}->{status}) }++
            if (!defined($self->{global}->{ lc($device_statuses->{$serial}->{status}) }))
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

Filter device name (Can be a regexp).

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

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-online', 'total-offline', 'total-alerting',
'traffic-in', 'traffic-out', 'connections-success', 'connections-auth',
'connections-assoc', 'connections-dhcp', 'connections-dns'.

=back

=cut
