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

package cloud::juniper::mist::restapi::mode::devices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_type_output {
    my ($self, %options) = @_;

    return "Device type '" . $options{instance_value}->{type} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL },
        { name => 'types', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_type_output',
          message_multiple => 'All device types are OK', skipped_code => { -10 => 1 } },
        { name => 'devices', type => COUNTER_TYPE_INSTANCE, prefix_output => "Device '%{name}' [%{type}] ",
          message_multiple => 'All monitored devices are OK', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'total', nlabel => 'mist.devices.total.count', display_ok => 0, threshold => 0,
            set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total devices: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'devices-disconnected', nlabel => 'mist.devices.disconnected.count',
            set => {
                key_values => [ { name => 'disconnected' }, { name => 'total' } ],
                output_template => 'disconnected: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        },
        {
            label => 'devices-disconnected-prct', nlabel => 'mist.devices.disconnected.percentage', display_ok => 0,
            set => {
                key_values => [ { name => 'disconnected_prct' } ],
                output_template => 'disconnected: %.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{types} = [
        {
            label => 'type-disconnected', nlabel => 'mist.devices.disconnected.count', threshold => 0,
            set => {
                key_values => [ { name => 'disconnected' }, { name => 'total' }, { name => 'type' } ],
                output_template => 'disconnected: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', label_extra_instance => 1, instance_use => 'type' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{devices} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            # Evaluated once per disconnected device (catalog_status_threshold_ng
            # runs per instance), so a maintenance window written as a negative
            # match silences only the devices it names and never neutralises the
            # alert for the others:
            #   --critical-status='%{status} ne "connected" && %{name} !~ /SW-MAINT/'
            # The aggregate %{disconnected}, %{disconnected_prct} and %{total}
            # are also exposed for count-based expressions. Silenced devices stay
            # counted in the disconnected perfdata and are not degrading.
            critical_default => '%{status} ne "connected"',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' }, { name => 'type' },
                    { name => 'disconnected' }, { name => 'disconnected_prct' }, { name => 'total' }
                ],
                output_template => "status: %{status}",
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'site-id:s'             => { name => 'site_id' },
        'filter-device-type:s'  => { name => 'filter_device_type' },
        'filter-device-name:s'  => { name => 'filter_device_name' },
        'exclude-device-name:s' => { name => 'exclude_device_name' }
    });

    return $self;
}

# /stats/devices honours site_id server-side, so the filter is passed straight
# through and only matching devices are downloaded. The endpoint returns a bare
# JSON array paginated with page/limit.
sub manage_selection {
    my ($self, %options) = @_;

    my $org_id = $options{custom}->get_org_id();
    my @get_param = ('type=all');
    push @get_param, 'site_id=' . $self->{option_results}->{site_id}
        if (defined($self->{option_results}->{site_id}) && $self->{option_results}->{site_id} ne '');

    my $devices = $options{custom}->request_api_paginated(
        endpoint => "/api/v1/orgs/$org_id/stats/devices",
        get_param => \@get_param
    );

    $self->{output}->option_exit(short_msg => "Unexpected response for /stats/devices (not an array).")
        if (ref($devices) ne 'ARRAY');

    my ($total, $disconnected) = (0, 0);
    my %by_type;
    my @disconnected_devices;

    foreach my $device (@$devices) {
        my $type = $device->{type} // 'unknown';
        my $name = (defined($device->{name}) && $device->{name} ne '') ? $device->{name} : ($device->{mac} // 'unknown');

        next if (defined($self->{option_results}->{filter_device_type}) && $self->{option_results}->{filter_device_type} ne ''
            && $type !~ /$self->{option_results}->{filter_device_type}/i);
        next if (defined($self->{option_results}->{filter_device_name}) && $self->{option_results}->{filter_device_name} ne ''
            && $name !~ /$self->{option_results}->{filter_device_name}/i);
        next if (defined($self->{option_results}->{exclude_device_name}) && $self->{option_results}->{exclude_device_name} ne ''
            && $name =~ /$self->{option_results}->{exclude_device_name}/i);

        $total++;
        $by_type{$type}->{total}++;
        $by_type{$type}->{disconnected} //= 0;

        my $status = $device->{status} // 'unknown';
        if ($status ne 'connected') {
            $disconnected++;
            $by_type{$type}->{disconnected}++;
            # Key the instance on the MAC (always present, unique) rather than the
            # display name, so two devices sharing a name are not collapsed.
            push @disconnected_devices, {
                instance => $device->{mac} // $device->{id} // $name,
                name => $name, type => $type, status => $status
            };
        }
    }

    $self->{output}->option_exit(short_msg => "No device matched the filters.")
        if ($total == 0);

    my $disconnected_prct = $total > 0 ? $disconnected * 100 / $total : 0;

    $self->{global} = {
        total => $total,
        disconnected => $disconnected,
        disconnected_prct => $disconnected_prct
    };

    $self->{types} = {};
    foreach my $type (keys %by_type) {
        $self->{types}->{$type} = {
            type => $type,
            total => $by_type{$type}->{total},
            disconnected => $by_type{$type}->{disconnected}
        };
    }

    # Only disconnected devices become instances: a maintenance-silenced device
    # is by definition disconnected, so it is still instantiated (counted and
    # evaluated) but the operator's negative-match rule keeps it non-degrading.
    $self->{devices} = {};
    foreach my $device (@disconnected_devices) {
        $self->{devices}->{ $device->{instance} } = {
            name => $device->{name},
            type => $device->{type},
            status => $device->{status},
            disconnected => $disconnected,
            disconnected_prct => $disconnected_prct,
            total => $total
        };
    }
}

1;

__END__

=head1 MODE

Check the connectivity of Juniper Mist devices (access points, switches,
gateways) from the C</stats/devices> endpoint.

By default, any disconnected device raises a CRITICAL. A device under
maintenance can be silenced with a negative-match C<--critical-status> rule
while remaining counted in the disconnected metric.

=over 8

=item B<--site-id>

Restrict the check to a single site (honoured server-side by the Mist API).

=item B<--filter-device-type>

Only keep devices whose type matches this regular expression (e.g. 'ap',
'switch', 'gateway').

=item B<--filter-device-name>

Only keep devices whose name matches this regular expression.

=item B<--exclude-device-name>

Exclude devices whose name matches this regular expression.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (per device).
You can use the following variables: %{status}, %{name}, %{type},
%{disconnected}, %{disconnected_prct}, %{total}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (per device)
(default: '%{status} ne "connected"').

Example - silence a switch under maintenance while still alerting on the rest:
--critical-status='%{status} ne "connected" && %{name} !~ /SW-MAINT/'

=item B<--warning-devices-disconnected> B<--critical-devices-disconnected>

Threshold on the absolute number of disconnected devices (no default).

=item B<--warning-devices-disconnected-prct> B<--critical-devices-disconnected-prct>

Threshold on the percentage of disconnected devices (no default).

=back

=cut
