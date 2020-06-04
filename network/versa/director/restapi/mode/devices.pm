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

package network::versa::director::restapi::mode::devices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use centreon::plugins::misc;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status services: %s [ping: %s] [sync: %s] [path: %s] [controller: %s]',
        $self->{result_values}->{services_status},
        $self->{result_values}->{ping_status},
        $self->{result_values}->{sync_status},
        $self->{result_values}->{path_status},
        $self->{result_values}->{controller_status}
    );
}

sub custom_memory_output {
    my ($self, %options) = @_;

    return sprintf(
        'memory total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub custom_disk_output {
    my ($self, %options) = @_;

    return sprintf(
        'disk total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output', indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'device_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'device_memory', type => 0, skipped_code => { -10 => 1 } },
                { name => 'device_disk', type => 0, skipped_code => { -10 => 1 } },
                { name => 'device_alarms', type => 0, cb_prefix_output => 'prefix_alarm_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'devices.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total'} ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{device_status} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'ping_status' }, { name => 'sync_status' },
                    { name => 'services_status' }, { name => 'path_status' },
                    { name => 'controller_status' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];

    $self->{maps_counters}->{device_memory} = [
        { label => 'memory-usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'memory-usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'memory-usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'memory used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{device_disk} = [
        { label => 'disk-usage', nlabel => 'disk.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_disk_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'disk-usage-free', display_ok => 0, nlabel => 'disk.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_disk_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'disk-usage-prct', display_ok => 0, nlabel => 'disk.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'disk used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{device_alarms} = [];
    foreach (('critical', 'major', 'minor', 'warning', 'indeterminate')) {
        push @{$self->{maps_counters}->{device_alarms}}, {
            label => 'alarms-' . $_, nlabel => 'alarms.' . $_ . '.count', 
            set => {
                key_values => [ { name => $_ }, { name => 'display' } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        };
    }   
}

sub device_long_output {
    my ($self, %options) = @_;

    return "checking device '" . $options{instance_value}->{display} . "' [type: " . $options{instance_value}->{type} . ']';
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return "Device '" . $options{instance_value}->{display} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Devices ';
}

sub prefix_alarm_output {
    my ($self, %options) = @_;

    return 'alarms ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-device-name:s'     => { name => 'filter_device_name' },
        'filter-device-type:s'     => { name => 'filter_device_type' },
        'filter-device-org-name:s' => { name => 'filter_device_org_name' },
        'unknown-status:s'         => { name => 'unknown_status', default => '' },
        'warning-status:s'         => { name => 'warning_status', default => '' },
        'critical-status:s'        => { name => 'critical_status', default => '%{ping_status} ne "reachable" or %{services_status} ne "good"' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'unknown_status', 'warning_status', 'critical_status'
    ]);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $organizations = $options{custom}->get_organizations();
    my $devices = $options{custom}->get_appliances();

    $self->{global} = { total => 0 };
    $self->{devices} = {};
    foreach my $device (values %{$devices->{entries}}) {
        if (defined($self->{option_results}->{filter_device_name}) && $self->{option_results}->{filter_device_name} ne '' &&
            $device->{name} !~ /$self->{option_results}->{filter_device_name}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $device->{name} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_device_type}) && $self->{option_results}->{filter_device_type} ne '' &&
            $device->{type} !~ /$self->{option_results}->{filter_device_type}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $device->{name} . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_device_org_name}) && $self->{option_results}->{filter_device_org_name} ne '') {
            my $matched = 0;
            foreach (@{$device->{orgs}}) {
                if ($organizations->{entries}->{ $_->{uuid} }->{name} =~ /$self->{option_results}->{filter_device_org_name}/) {
                    $matched = 1;
                    last;
                }
            }
            if ($matched == 0) {
                $self->{output}->output_add(long_msg => "skipping device '" . $device->{name} . "': no matching filter org.", debug => 1);
                next;
            }
        }

        #"ping-status": "REACHABLE",
        #"sync-status": "OUT_OF_SYNC",
        #"services-status": "GOOD",
        #"overall-status": "POWERED_ON",
        #"controller-status": "Unavailable",
        #"path-status": "Unavailable",
        # "Hardware": {
        #     "memory": "7.80GiB",
	    #     "freeMemory": "1.19GiB",
	    #     "diskSize": "80G",
	    #     "freeDisk": "33G",
        #}
        my $appliance_status = $options{custom}->execute(endpoint => '/vnms/dashboard/applianceStatus/' . $device->{uuid});

        $self->{devices}->{ $device->{name} } = {
            display => $device->{name},
            type => $device->{type},
            device_status => {
                display => $device->{name},
                ping_status => lc($appliance_status->{'versanms.ApplianceStatus'}->{'ping-status'}),
                sync_status => lc($appliance_status->{'versanms.ApplianceStatus'}->{'sync-status'}),
                services_status => lc($appliance_status->{'versanms.ApplianceStatus'}->{'services-status'}),
                path_status => lc($appliance_status->{'versanms.ApplianceStatus'}->{'path-status'}),
                controller_status => lc($appliance_status->{'versanms.ApplianceStatus'}->{'controller-status'})
            },
            device_alarms => {
                display => $device->{name}
            }
        };

        my $total = centreon::plugins::misc::convert_bytes(
            value => $appliance_status->{'versanms.ApplianceStatus'}->{Hardware}->{memory},
            pattern => '([0-9\.]+)(.*)$'
        );
        my $free = centreon::plugins::misc::convert_bytes(
            value => $appliance_status->{'versanms.ApplianceStatus'}->{Hardware}->{freeMemory},
            pattern => '([0-9\.]+)(.*)$'
        );
        $self->{devices}->{ $device->{name} }->{device_memory} = {
            display => $device->{name},
            total => $total,
            free => $free,
            used => $total - $free,
            prct_used => 100 - ($free * 100 / $total),
            prct_free => ($free * 100 / $total)
        };

        $total = centreon::plugins::misc::convert_bytes(
            value => $appliance_status->{'versanms.ApplianceStatus'}->{Hardware}->{diskSize},
            pattern => '([0-9\.]+)(.*)$'
        );
        $free = centreon::plugins::misc::convert_bytes(
            value => $appliance_status->{'versanms.ApplianceStatus'}->{Hardware}->{freeDisk},
            pattern => '([0-9\.]+)(.*)$'
        );
        $self->{devices}->{ $device->{name} }->{device_disk} = {
            display => $device->{name},
            total => $total,
            free => $free,
            used => $total - $free,
            prct_used => 100 - ($free * 100 / $total),
            prct_free => ($free * 100 / $total)
        };

        foreach (@{$appliance_status->{'versanms.ApplianceStatus'}->{alarmSummary}->{rows}}) {
            $self->{devices}->{ $device->{name} }->{device_alarms}->{ lc($_->{firstColumnValue}) } = $_->{columnValues}->[0];
        }

        $self->{global}->{total}++;
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

Filter device by name (Can be a regexp).

=item B<--filter-device-type>

Filter device by type (Can be a regexp).

=item B<--filter-device-org-name>

Filter device by organization name (Can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{ping_status}, %{services_status}, %{sync_status}, %{controller_status}, %{path_status}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{ping_status}, %{service_sstatus}, %{sync_status}, %{controller_status}, %{path_status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{ping_status} ne "reachable" or %{services_status} ne "good"').
Can used special variables like: %{ping_status}, %{services_status}, %{sync_status}, %{controller_status}, %{path_status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total',
'traffic-in', 'traffic-out', 'connections-success', 'connections-auth',
'connections-assoc', 'connections-dhcp', 'connections-dns'.

=back

=cut
