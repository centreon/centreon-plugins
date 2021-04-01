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

package centreon::common::cisco::standard::snmp::mode::components::voltage;

use strict;
use warnings;

my %map_voltage_state = (
    1 => 'normal', 
    2 => 'warning', 
    3 => 'critical', 
    4 => 'shutdown',
    5 => 'not present',
    6 => 'not functioning',
);

# In MIB 'CISCO-ENVMON-MIB'
my $mapping = {
    ciscoEnvMonVoltageStatusDescr => { oid => '.1.3.6.1.4.1.9.9.13.1.2.1.2' },
    ciscoEnvMonVoltageStatusValue => { oid => '.1.3.6.1.4.1.9.9.13.1.2.1.3' },
    ciscoEnvMonVoltageThresholdLow => { oid => '.1.3.6.1.4.1.9.9.13.1.2.1.4' },
    ciscoEnvMonVoltageThresholdHigh => { oid => '.1.3.6.1.4.1.9.9.13.1.2.1.5' },
    ciscoEnvMonVoltageState => { oid => '.1.3.6.1.4.1.9.9.13.1.2.1.7', map => \%map_voltage_state },
};
my $oid_ciscoEnvMonVoltageStatusEntry = '.1.3.6.1.4.1.9.9.13.1.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_ciscoEnvMonVoltageStatusEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_ciscoEnvMonVoltageStatusEntry}})) {
        next if ($oid !~ /^$mapping->{ciscoEnvMonVoltageState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_ciscoEnvMonVoltageStatusEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'voltage', instance => $instance, name => $result->{ciscoEnvMonVoltageStatusDescr}));
        $self->{components}->{voltage}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Voltage '%s' status is %s [instance: %s] [value: %s C]", 
                                    $result->{ciscoEnvMonVoltageStatusDescr}, $result->{ciscoEnvMonVoltageState},
                                    $instance, $result->{ciscoEnvMonVoltageStatusValue}));
        my $exit = $self->get_severity(section => 'voltage', instance => $instance, value => $result->{ciscoEnvMonVoltageState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s' status is %s", 
                                                             $result->{ciscoEnvMonVoltageStatusDescr}, $result->{ciscoEnvMonVoltageState}));
        }

        $result->{ciscoEnvMonVoltageStatusValue} = $result->{ciscoEnvMonVoltageStatusValue} / 1000;
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, name => $result->{ciscoEnvMonVoltageStatusDescr}, value => $result->{ciscoEnvMonVoltageStatusValue});
        if ($checked == 0) {
            my $warn_th = undef;
            my $crit_th = ((defined($result->{ciscoEnvMonVoltageThresholdLow}) && $result->{ciscoEnvMonVoltageThresholdLow} =~ /\d/) ? sprintf("%.3f", $result->{ciscoEnvMonVoltageThresholdLow} / 1000) : 0) . ':' . 
                ((defined($result->{ciscoEnvMonVoltageThresholdHigh}) && $result->{ciscoEnvMonVoltageThresholdHigh} =~ /\d/) ? sprintf("%.3f", $result->{ciscoEnvMonVoltageThresholdHigh} / 1000) : '');
            $self->{perfdata}->threshold_validate(label => 'warning-voltage-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-voltage-instance-' . $instance, value => $crit_th);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-voltage-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-voltage-instance-' . $instance);
        }
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Voltage '%s' is %.3f V", $result->{ciscoEnvMonVoltageStatusDescr}, $result->{ciscoEnvMonVoltageStatusValue}));
        }
        $self->{output}->perfdata_add(
            label => "voltage", unit => 'V',
            nlabel => 'hardware.voltage.volt',
            instances => $result->{ciscoEnvMonVoltageStatusDescr},
            value => sprintf("%.3f", $result->{ciscoEnvMonVoltageStatusValue}),
            warning => $warn,
            critical => $crit
        );
    }
}

1;
