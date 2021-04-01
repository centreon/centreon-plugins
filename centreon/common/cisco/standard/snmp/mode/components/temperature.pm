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

package centreon::common::cisco::standard::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_temperature_state = (
    1 => 'normal', 
    2 => 'warning', 
    3 => 'critical', 
    4 => 'shutdown',
    5 => 'not present',
    6 => 'not functioning',
);

# In MIB 'CISCO-ENVMON-MIB'
my $mapping = {
    ciscoEnvMonTemperatureStatusDescr => { oid => '.1.3.6.1.4.1.9.9.13.1.3.1.2' },
    ciscoEnvMonTemperatureStatusValue => { oid => '.1.3.6.1.4.1.9.9.13.1.3.1.3' },
    ciscoEnvMonTemperatureThreshold => { oid => '.1.3.6.1.4.1.9.9.13.1.3.1.4' },
    ciscoEnvMonTemperatureState => { oid => '.1.3.6.1.4.1.9.9.13.1.3.1.6', map => \%map_temperature_state },
};
my $oid_ciscoEnvMonTemperatureStatusEntry = '.1.3.6.1.4.1.9.9.13.1.3.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_ciscoEnvMonTemperatureStatusEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_ciscoEnvMonTemperatureStatusEntry}})) {
        next if ($oid !~ /^$mapping->{ciscoEnvMonTemperatureState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_ciscoEnvMonTemperatureStatusEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance, name => $result->{ciscoEnvMonTemperatureStatusDescr}));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "Temperature '%s' status is %s [instance: %s] [value: %s C]", 
                $result->{ciscoEnvMonTemperatureStatusDescr}, $result->{ciscoEnvMonTemperatureState},
                $instance, defined($result->{ciscoEnvMonTemperatureStatusValue}) ? $result->{ciscoEnvMonTemperatureStatusValue} : '-'
            )
        );
        my $exit = $self->get_severity(section => 'temperature', instance => $instance, value => $result->{ciscoEnvMonTemperatureState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is %s", 
                                                             $result->{ciscoEnvMonTemperatureStatusDescr}, $result->{ciscoEnvMonTemperatureState}));
        }

        next if (!defined($result->{ciscoEnvMonTemperatureStatusValue}));

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, name => $result->{ciscoEnvMonTemperatureStatusDescr}, value => $result->{ciscoEnvMonTemperatureStatusValue});
        if ($checked == 0) {
            my $warn_th = undef;
            my $crit_th = '~:' . $result->{ciscoEnvMonTemperatureThreshold};
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        }
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Temperature '%s' is %s degree centigrade", $result->{ciscoEnvMonTemperatureStatusDescr}, $result->{ciscoEnvMonTemperatureStatusValue}));
        }
        $self->{output}->perfdata_add(
            label => "temp", unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $result->{ciscoEnvMonTemperatureStatusDescr},
            value => $result->{ciscoEnvMonTemperatureStatusValue},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
