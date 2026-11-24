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

package storage::ibm::flashsystem::restapi::mode::hardware;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_empty is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $component_commands = [
    { command => 'lsenclosure',          label => 'enclosure' },
    { command => 'lsnodecanister',       label => 'node canister' },
    { command => 'lsenclosurecanister',  label => 'expansion canister', id_fields => [ 'canister_id' ] },
    { command => 'lsenclosurepsu',       label => 'power supply', id_fields => [ 'PSU_id' ] },
    { command => 'lsenclosurebattery',   label => 'battery', id_fields => [ 'battery_id' ] },
    { command => 'lsenclosurefanmodule', label => 'fan module', id_fields => [ 'fan_module_id' ] },
    { command => 'lsdrive',              label => 'drive' },
    { command => 'lsarray',              label => 'array', id_fields => [ 'mdisk_name', 'mdisk_id' ] },
    { command => 'lsmdisk',              label => 'mdisk' },
    { command => 'lsquorum',             label => 'quorum', id_fields => [ 'quorum_index' ] }
];

my $enclosure_subsystems = [
    { field => 'PSUs',        label => 'power supplies' },
    { field => 'canisters',   label => 'canisters' },
    { field => 'fan_modules', label => 'fan modules' },
    { field => 'sems',        label => 'secondary expander modules' }
];

my $environment_stats = [
    { stat => 'temp_c',  key => 'temperature' },
    { stat => 'power_w', key => 'power' }
];

sub prefix_component_output {
    my ($self, %options) = @_;

    return ucfirst($options{instance_value}->{type}) . " '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Hardware: ' },
        { name => 'components', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_component_output',
          message_multiple => 'All hardware components are online', skipped_code => { NO_VALUE() => 1 } },
        { name => 'environment', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Enclosure: ' },
        { name => 'subsystems', type => COUNTER_TYPE_INSTANCE, prefix_output => "Enclosure '%{enclosure}' ",
          message_multiple => 'All enclosure subsystems are fully populated', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{environment} = [
        { label => 'temperature', nlabel => 'hardware.temperature.celsius', set => {
                key_values => [ { name => 'temperature' } ],
                output_template => 'temperature %s C',
                perfdatas => [ { template => '%s', unit => 'C' } ]
            }
        },
        { label => 'power', nlabel => 'hardware.power.watt', set => {
                key_values => [ { name => 'power' } ],
                output_template => 'power draw %s W',
                perfdatas => [ { template => '%s', unit => 'W', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'components-detected', nlabel => 'hardware.components.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => '%s component(s)',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'components-degraded', nlabel => 'hardware.components.degraded.count', set => {
                key_values => [ { name => 'degraded' } ],
                output_template => '%s not online',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{components} = [
        {
            label => 'component-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{status} =~ /^(offline|excluded)$/i',
            warning_default => '%{status} =~ /^(degraded|degraded_paths|degraded_ports)$/i',
            set => {
                key_values => [ { name => 'name' }, { name => 'type' }, { name => 'status' } ],
                output_template => 'status: %{status}',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{subsystems} = [
        {
            label => 'subsystem-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{online} == 0',
            warning_default => '%{online} < %{total}',
            set => {
                key_values => [ { name => 'enclosure' }, { name => 'label' }, { name => 'online' }, { name => 'total' } ],
                output_template => '%{label} online: %{online}/%{total}',
                closure_custom_perfdata => sub { return 0; },
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
        'include-type:s' => { name => 'include_type' },
        'exclude-type:s' => { name => 'exclude_type' },
        'include-name:s' => { name => 'include_name' },
        'exclude-name:s' => { name => 'exclude_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { detected => 0, degraded => 0 };
    $self->{environment} = {};
    $self->{components} = {};
    $self->{subsystems} = {};

    my %stats;
    foreach my $entry (@{$options{custom}->request_optional(command => 'lssystemstats')}) {
        next if (ref($entry) ne 'HASH' || !defined($entry->{stat_name}));
        $stats{$entry->{stat_name}} = $entry->{stat_current};
    }
    foreach my $measure (@$environment_stats) {
        my $value = $stats{$measure->{stat}};
        next if (!defined($value) || $value !~ /^-?\d+(?:\.\d+)?$/);
        $self->{environment}->{$measure->{key}} = $value;
    }

    foreach my $family (@$component_commands) {
        next if (is_excluded($family->{label}, $self->{option_results}->{include_type}, $self->{option_results}->{exclude_type}));

        foreach my $entry (@{$options{custom}->request_optional(command => $family->{command})}) {
            my $name = '';
            foreach my $field ('name', @{$family->{id_fields} // []}, 'id') {
                next if (is_empty($entry->{$field}));
                $name = $entry->{$field};
                last;
            }
            next if (is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}));

            my $status = $entry->{status} // '';

            $self->{global}->{detected}++;
            $self->{global}->{degraded}++ if ($status !~ /^online$/i);

            $self->{components}->{$family->{label} . '.' . $name} = {
                name => $name,
                type => $family->{label},
                status => $status
            };

            next if ($family->{command} ne 'lsenclosure');

            foreach my $subsystem (@$enclosure_subsystems) {
                my $online = $entry->{'online_' . $subsystem->{field}};
                my $total = $entry->{'total_' . $subsystem->{field}};

                next if (!defined($online) || !defined($total) || $online !~ /^\d+$/ || $total !~ /^\d+$/);
                next if ($total == 0);

                $self->{subsystems}->{$name . '.' . $subsystem->{field}} = {
                    enclosure => $name,
                    label => $subsystem->{label},
                    online => $online,
                    total => $total
                };
            }
        }
    }
}

1;

__END__

=head1 MODE

Check hardware components (enclosures, canisters, power supplies, batteries, fan modules, drives, arrays, mdisks, quorum devices), enclosure subsystems and environment.

=over 8

=item B<--include-type>

Filter component families by label (C<enclosure>, C<node canister>, C<expansion canister>, C<power supply>, C<battery>, C<fan module>, C<drive>, C<array>, C<mdisk>, C<quorum>) (can be a regexp).

=item B<--exclude-type>

Exclude component families by label (C<enclosure>, C<node canister>, C<expansion canister>, C<power supply>, C<battery>, C<fan module>, C<drive>, C<array>, C<mdisk>, C<quorum>) (can be a regexp).

=item B<--include-name>

Filter components by name or id (can be a regexp).

=item B<--exclude-name>

Exclude components by name or id (can be a regexp).

=item B<--warning-component-status>

Define the conditions to match for the status to be WARNING (default: C<'%{status} =~ /^(degraded|degraded_paths|degraded_ports)$/i'>).
You can use the following variables: C<%{name}>, C<%{type}>, C<%{status}>

=item B<--critical-component-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} =~ /^(offline|excluded)$/i'>).
You can use the following variables: C<%{name}>, C<%{type}>, C<%{status}>

=item B<--unknown-component-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{type}>, C<%{status}>

=item B<--warning-subsystem-status>

Define the conditions to match for the status to be WARNING (default: C<< '%{online} < %{total}' >>).
You can use the following variables: C<%{enclosure}>, C<%{label}>, C<%{online}>, C<%{total}>

=item B<--critical-subsystem-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{online} == 0'>).
You can use the following variables: C<%{enclosure}>, C<%{label}>, C<%{online}>, C<%{total}>

=item B<--unknown-subsystem-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{enclosure}>, C<%{label}>, C<%{online}>, C<%{total}>

=item B<--warning-components-detected>

Threshold.

=item B<--critical-components-detected>

Threshold.

=item B<--warning-components-degraded>

Threshold.

=item B<--critical-components-degraded>

Threshold.

=item B<--warning-temperature>

Threshold in degrees Celsius.

=item B<--critical-temperature>

Threshold in degrees Celsius.

=item B<--warning-power>

Threshold in watts.

=item B<--critical-power>

Threshold in watts.

=back

=cut
