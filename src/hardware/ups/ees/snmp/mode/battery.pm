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

package hardware::ups::ees::snmp::mode::battery;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $map_battery_mode = {
    1  => 'unknown',
    2  => 'FloatCharging',
    3  => 'ShortTest',
    4  => 'BoostChargingForTest',
    5  => 'ManualTesting',
    6  => 'PlanTesting',
    7  => 'ACFailTesting',
    8  => 'ACFail',
    9  => 'ManualBoostCharging',
    10 => 'AutoBoostCharging',
    11 => 'CyclicBoostCharging',
    12 => 'MasterBoostCharging',
    13 => 'MasterBateryTesting'
};

sub battery_mode_custom_output {
    my ($self, %options) = @_;

    return sprintf("Battery mode: '%s'", $self->{result_values}->{battery_mode});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'battery', type => 0 }
    ];

    $self->{maps_counters}->{battery} = [
        {
            label => 'voltage', nlabel => 'battery.voltage.volt',
            set   => {
                key_values      => [ { name => 'voltage' } ],
                output_template => 'voltage: %.2fV',
                perfdatas       => [ { template => '%.2f', unit => 'V' } ],
            }
        },
        {
            label => 'current', nlabel => 'battery.current.ampere',
            set   => {
                key_values      => [ { name => 'current' } ],
                output_template => 'current: %.2fA',
                perfdatas       => [ { template => '%.2f', unit => 'A' } ],
            }
        },
        {
            label => 'capacity', nlabel => 'battery.capacity.percentage',
            set   => {
                key_values      => [ { name => 'capacity' } ],
                output_template => 'capacity: %.2f%%',
                perfdatas       => [ { template => '%.2f', min => 0, max => 100, unit => '%' } ],
            }
        },
        {
            label => 'nominal-capacity', nlabel => 'battery.nominal.capacity.amperehour',
            set   => {
                key_values      => [ { name => 'nominal_capacity' } ],
                output_template => 'used capacity: %.2fAh',
                perfdatas       => [ { template => '%.2f', unit => 'Ah' } ],
            }
        },
        {
            label            => 'battery-mode',
            unknown_default  => '%{battery_mode} =~ /unknown/i',
            warning_default  => '%{battery_mode} =~ /ShortTest|BoostChargingForTest|ManualTesting|PlanTesting|ManualBoostCharging|AutoBoostCharging|CyclicBoostCharging|MasterBoostCharging|MasterBateryTesting/i',
            critical_default => '%{battery_mode} =~ /ACFailTesting|ACFail/i',
            type             => 2,
            set              => {
                key_values                     => [ { name => 'battery_mode' } ],
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_output          => $self->can('battery_mode_custom_output')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_psStatusBatteryMode = '.1.3.6.1.4.1.6302.2.1.2.9.0';
    my $oid_psBatteryVoltage = '.1.3.6.1.4.1.6302.2.1.2.5.1.0';
    my $oid_psTotalBatteryCurrent = '.1.3.6.1.4.1.6302.2.1.2.5.2.0';
    my $oid_psBatteryCapacity = '.1.3.6.1.4.1.6302.2.1.2.5.3.0';
    my $oid_psBatteryNominalCapacity = '.1.3.6.1.4.1.6302.2.1.2.5.4.0';

    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_psStatusBatteryMode,
            $oid_psBatteryVoltage,
            $oid_psTotalBatteryCurrent,
            $oid_psBatteryCapacity,
            $oid_psBatteryNominalCapacity
        ],
        nothing_quit => 1
    );

    $self->{battery} = {
        voltage          => $snmp_result->{$oid_psBatteryVoltage} / 1000,
        current          => $snmp_result->{$oid_psTotalBatteryCurrent} / 1000,
        capacity         => $snmp_result->{$oid_psBatteryCapacity} / 1000,
        nominal_capacity => $snmp_result->{$oid_psBatteryNominalCapacity} / 1000,
        battery_mode     => $map_battery_mode->{$snmp_result->{$oid_psStatusBatteryMode}},
    };
}

1;

__END__

=head1 MODE

Check battery.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds: voltage (V), current (A), capacity (%), nominal-capacity (Ah)

=item B<--unknown-battery-mode>

Define the conditions to match for the status to be UNKNOWN (default: '%{battery_mode} =~ /unknown/i').
You can use the following variables: %{battery_mode}

=item B<--warning-battery-mode>

Define the conditions to match for the status to be WARNING (default: '%{battery_mode} =~ /ShortTest|BoostChargingForTest|ManualTesting|PlanTesting|ManualBoostCharging|AutoBoostCharging|CyclicBoostCharging|MasterBoostCharging|MasterBateryTesting/i').
You can use the following variables: %{battery_mode}

=item B<--critical-battery-mode>

Define the conditions to match for the status to be CRITICAL (default: '%{battery_mode} =~ /ACFailTesting|ACFail/i').
You can use the following variables: %{battery_mode}

=back

=cut
