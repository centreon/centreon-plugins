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

package hardware::server::hp::proliant::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_temperature_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
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

# In MIB 'CPQSTDEQ-MIB.mib'
my $mapping = {
    cpqHeTemperatureLocale => { oid => '.1.3.6.1.4.1.232.6.2.6.8.1.3', map => \%map_location },
    cpqHeTemperatureCelsius => { oid => '.1.3.6.1.4.1.232.6.2.6.8.1.4' },
    cpqHeTemperatureThreshold => { oid => '.1.3.6.1.4.1.232.6.2.6.8.1.5' },
    cpqHeTemperatureCondition => { oid => '.1.3.6.1.4.1.232.6.2.6.8.1.6', map => \%map_temperature_condition },
};
my $oid_cpqHeTemperatureEntry = '.1.3.6.1.4.1.232.6.2.6.8.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqHeTemperatureEntry, start => $mapping->{cpqHeTemperatureLocale}->{oid}, end => $mapping->{cpqHeTemperatureCondition}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqHeTemperatureEntry}})) {
        next if ($oid !~ /^$mapping->{cpqHeTemperatureCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqHeTemperatureEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("'%s' %s temperature is %dC (%d max) (status is %s).", 
                                    $instance, $result->{cpqHeTemperatureLocale}, $result->{cpqHeTemperatureCelsius},
                                    $result->{cpqHeTemperatureThreshold},
                                    $result->{cpqHeTemperatureCondition}));
        my $exit = $self->get_severity(section => 'temperature', value => $result->{cpqHeTemperatureCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("temperature '%s' %s status is %s", 
                                            $instance, $result->{cpqHeTemperatureLocale}, $result->{cpqHeTemperatureCondition}));
        }
        
        if (defined($result->{cpqHeTemperatureCelsius}) && $result->{cpqHeTemperatureCelsius} != -1) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{cpqHeTemperatureCelsius});
            if ($checked == 0) {
                my $warn_th = '';
                my $crit_th = $result->{cpqHeTemperatureThreshold} != -1 ? $result->{cpqHeTemperatureThreshold} : '';
                $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
            }
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Temperature '%s' %s is %s degree centigrade", $instance, $result->{cpqHeTemperatureLocale}, $result->{cpqHeTemperatureCelsius}));
            }
            $self->{output}->perfdata_add(
                label => "temp", unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => [$instance, $result->{cpqHeTemperatureLocale}],
                value => $result->{cpqHeTemperatureCelsius},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
