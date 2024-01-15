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

package hardware::server::dell::idrac::snmp::mode::components::health;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status);

my $mapping_health = {
    psuComb         => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.9', map => \%map_status, label => 'psuAll' }, # systemStatePowerSupplyStatusCombined
    voltageComb     => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.12', map => \%map_status, label => 'voltageAll' }, # systemStateVoltageStatusCombined
    amperageComb    => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.15', map => \%map_status, label => 'amperageAll' }, # systemStateAmperageStatusCombined
    coolingDevComb  => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.21', map => \%map_status, label => 'coolingDeviceAll' }, # systemStateCoolingDeviceStatusCombined
    tempComb        => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.24', map => \%map_status, label => 'temperatureAll' }, # systemStateTemperatureStatusCombined
    memoryComb      => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.27', map => \%map_status, label => 'memoryAll' }, # systemStateMemoryDeviceStatusCombined
    intrusionComb   => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.30', map => \%map_status, label => 'intrusionAll' }, # systemStateChassisIntrusionStatusCombined
    powerComb       => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.42', map => \%map_status, label => 'powerUnitAll' }, # systemStatePowerUnitStatusCombined
    coolingUnitComb => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.44', map => \%map_status, label => 'coolingUnitAll' }, # systemStateCoolingUnitStatusCombined
    processorComb   => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.50', map => \%map_status, label => 'processorAll' }, # systemStateProcessorDeviceStatusCombined
    batteryComb     => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.52', map => \%map_status, label => 'batteryAll' }, # systemStateBatteryStatusCombined
    sdCardUnitComb  => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.54', map => \%map_status, label => 'sdCardUnitAll' }, # systemStateSDCardUnitStatusCombined
    sdCardDevComb   => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.56', map => \%map_status, label => 'sdCardDeviceAll' }, # systemStateSDCardDeviceStatusCombined
    idsmCardDevComb => { oid => '.1.3.6.1.4.1.674.10892.5.4.200.10.1.60', map => \%map_status, label => 'idsmCardDeviceAll' } # systemStateIDSDMCardDeviceStatusCombined
};

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking health");
    $self->{components}->{health} = { name => 'health', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'health'));

    my $instances = $self->get_chassis_instances();

    return if (scalar(@$instances) <= 0);

    $self->{snmp}->load(
        oids => [map($_->{oid}, values(%$mapping_health))],
        instances => $instances
    );
    my $results = $self->{snmp}->get_leef();

    foreach my $instance (@$instances) {
        my $result = $self->{snmp}->map_instance(mapping => $mapping_health, results => $results, instance => $instance);
        my $chassis_name = $self->get_chassis_name(id => $instance);

        foreach (keys %$mapping_health) {
            next if (!defined($result->{$_}));

            my $name = $chassis_name . ':' . $mapping_health->{$_}->{label};
            next if ($self->check_filter(section => 'health', instance => $instance, name => $name));
            $self->{components}->{health}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "health '%s' status is %s [instance: %s]",
                    $name,
                    $result->{$_},
                    $instance
                )
            );
            my $exit = $self->get_severity(label => 'default.status', section => 'health', value => $result->{$_});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Health '%s' status is %s", $name, $result->{$_})
                );
            }
        }
    }
}

1;
