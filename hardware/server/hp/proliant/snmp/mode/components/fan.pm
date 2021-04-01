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

package hardware::server::hp::proliant::snmp::mode::components::fan;

use strict;
use warnings;

my %map_fan_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);
my %map_present = (
    1 => 'other',
    2 => 'absent',
    3 => 'present',
);
my %map_redundant = (
    1 => 'other',
    2 => 'not redundant',
    3 => 'redundant',
);
my %map_location = (
    1 => "other",
    2 => "unknown",
    3 => "system",
    4 => "systemBoard",
    5 => "ioBoard",
    6 => "cpu",
    7 => "memory",
    8 => "storage",
    9 => "removableMedia",
    10 => "powerSupply", 
    11 => "ambient",
    12 => "chassis",
    13 => "bridgeCard",
    14 => "managementBoard",
    15 => "backplane",
    16 => "networkSlot",
    17 => "bladeSlot",
    18 => "virtual",
);
my %map_fanspeed = (
    1 => "other",
    2 => "normal",
    3 => "high",
);

# In MIB 'CPQHLTH-MIB.mib'
my $mapping = {
    cpqHeFltTolFanLocale => { oid => '.1.3.6.1.4.1.232.6.2.6.7.1.3', map => \%map_location },
    cpqHeFltTolFanPresent => { oid => '.1.3.6.1.4.1.232.6.2.6.7.1.4', map => \%map_present },
    cpqHeFltTolFanSpeed => { oid => '.1.3.6.1.4.1.232.6.2.6.7.1.6', map => \%map_fanspeed },
    cpqHeFltTolFanRedundant => { oid => '.1.3.6.1.4.1.232.6.2.6.7.1.7',  map => \%map_redundant },
    cpqHeFltTolFanRedundantPartner => { oid => '.1.3.6.1.4.1.232.6.2.6.7.1.8' },
    cpqHeFltTolFanCondition => { oid => '.1.3.6.1.4.1.232.6.2.6.7.1.9', map => \%map_fan_condition },
    cpqHeFltTolFanCurrentSpeed => { oid => '.1.3.6.1.4.1.232.6.2.6.7.1.12' },
};
my $oid_cpqHeFltTolFanEntry = '.1.3.6.1.4.1.232.6.2.6.7.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqHeFltTolFanEntry, start => $mapping->{cpqHeFltTolFanLocale}->{oid}, end => $mapping->{cpqHeFltTolFanCurrentSpeed}->{oid} };
}

sub check {
    my ($self) = @_;

    
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqHeFltTolFanEntry}})) {
        next if ($oid !~ /^$mapping->{cpqHeFltTolFanCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqHeFltTolFanEntry}, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance));
        next if ($result->{cpqHeFltTolFanPresent} !~ /present/i && 
                 $self->absent_problem(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is %s, speed is %s [location: %s, redundance: %s, redundant partner: %s].",
                                    $instance, $result->{cpqHeFltTolFanCondition}, $result->{cpqHeFltTolFanSpeed},
                                    $result->{cpqHeFltTolFanLocale},
                                    $result->{cpqHeFltTolFanRedundant}, $result->{cpqHeFltTolFanRedundantPartner}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{cpqHeFltTolFanCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("fan '%s' status is %s",
                                           $instance, $result->{cpqHeFltTolFanCondition}));
        }

        if (defined($result->{cpqHeFltTolFanCurrentSpeed})) {
            $self->{output}->perfdata_add(
                label => 'fan_speed', unit => 'rpm',
                nlabel => 'hardware.fan.speed.rpm',
                instances => $instance,
                value => $result->{cpqHeFltTolFanCurrentSpeed}
            );
        }
    }
}

1;
