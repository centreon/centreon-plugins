#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package hardware::ats::apc::snmp::mode::components::entity;

use strict;
use warnings;

my %map_com = (1 => 'atsNeverDiscovered', 2 => 'atsCommEstablished', 3 => 'atsCommLost');
my %map_redunt = (1 => 'atsRedundancyLost', 2 => 'atsFullyRedundant');
my %map_current = (1 => 'atsOverCurrent', 2 => 'atsCurrentOK');
my %map_power = (1 => 'atsPowerSupplyFailure', 2 => 'atsPowerSupplyOK');
my %map_fail = (1 => 'fail', 2 => 'ok');
my %map_sync = (1 => 'inSync', 2 => 'outOfSync');

my $mapping = {
    atsStatusCommStatus             => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.1', map => \%map_com, label => 'CommStatus' },
    atsStatusRedundancyState        => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.3', map => \%map_redunt, label => 'RedundancyState' },
    atsStatusOverCurrentState       => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.4', map => \%map_current, label => 'OverCurrentState' },
    atsStatus5VPowerSupply          => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.5', map => \%map_power, label => '5VPowerSupply' },
    atsStatus24VPowerSupply         => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.6', map => \%map_power, label => '24VPowerSupply' },
    atsStatus24VSourceBPowerSupply  => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.7', map => \%map_power, label => '24VSourceBPowerSupply' },
    atsStatusPlus12VPowerSupply     => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.8', map => \%map_power, label => 'Plus12VPowerSupply' },
    atsStatusMinus12VPowerSupply    => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.9', map => \%map_power, label => 'Minus12VPowerSupply' },
    atsStatusSwitchStatus           => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.10', map => \%map_fail, label => 'SwitchStatus' },
    atsStatusSourceAStatus          => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.12', map => \%map_fail, label => 'SourceAStatus' },
    atsStatusSourceBStatus          => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.13', map => \%map_fail, label => 'SourceBStatus' },
    atsStatusPhaseSyncStatus        => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.14', map => \%map_sync, label => 'PhaseSyncStatus' },
    atsStatusVoltageOutStatus       => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.15', map => \%map_fail, label => 'VoltageOutStatus' },
    atsStatusHardwareStatus         => { oid => '.1.3.6.1.4.1.318.1.1.8.5.1.16', map => \%map_fail, label => 'HardwareStatus' },
};

my $oid_atsStatusDeviceStatus = '.1.3.6.1.4.1.318.1.1.8.5.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_atsStatusDeviceStatus };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking entities");
    $self->{components}->{entity} = {name => 'entities', total => 0, skip => 0};
    return if ($self->check_filter(section => 'entity'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_atsStatusDeviceStatus}, instance => '0');
    foreach (sort keys %{$mapping}) {
        next if ($self->check_filter(section => 'entity', instance => $mapping->{$_}->{label}));
        $self->{components}->{entity}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("entity '%s' status is '%s' [instance = %s]",
                                                        $mapping->{$_}->{label}, defined($result->{$_}) ? $result->{$_} : 'n/a', $mapping->{$_}->{label}));
        
        next if (!defined($result->{$_}));
        my $exit = $self->get_severity(section => 'entity', instance => $mapping->{$_}->{label}, value => $result->{$_});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Entity '%s' status is '%s'", $mapping->{$_}->{label}, $result->{$_}));
        }
    }
}

1;