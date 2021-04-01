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

package storage::dell::equallogic::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_temperature_status = (
    0 => 'unknown', 
    1 => 'normal', 
    2 => 'warning', 
    3 => 'critical',
);

# In MIB 'eqlcontroller.mib'
my $mapping = {
    eqlMemberHealthDetailsTemperatureName => { oid => '.1.3.6.1.4.1.12740.2.1.6.1.2' },
    eqlMemberHealthDetailsTemperatureValue => { oid => '.1.3.6.1.4.1.12740.2.1.6.1.3' },
    eqlMemberHealthDetailsTemperatureCurrentState => { oid => '.1.3.6.1.4.1.12740.2.1.6.1.4', map => \%map_temperature_status },
    eqlMemberHealthDetailsTemperatureHighCriticalThreshold => { oid => '.1.3.6.1.4.1.12740.2.1.6.1.5' },
    eqlMemberHealthDetailsTemperatureHighWarningThreshold => { oid => '.1.3.6.1.4.1.12740.2.1.6.1.6' },
    eqlMemberHealthDetailsTemperatureLowCriticalThreshold => { oid => '.1.3.6.1.4.1.12740.2.1.6.1.7' },
    eqlMemberHealthDetailsTemperatureLowWarningThreshold => { oid => '.1.3.6.1.4.1.12740.2.1.6.1.8' },
};
my $oid_eqlMemberHealthDetailsTemperatureEntry = '.1.3.6.1.4.1.12740.2.1.6.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_eqlMemberHealthDetailsTemperatureEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_eqlMemberHealthDetailsTemperatureEntry}})) {
        next if ($oid !~ /^$mapping->{eqlMemberHealthDetailsTemperatureCurrentState}->{oid}\.(\d+\.\d+)\.(.*)$/);
        my ($member_instance, $instance) = ($1, $2);
        my $member_name = $self->get_member_name(instance => $member_instance);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_eqlMemberHealthDetailsTemperatureEntry}, instance => $member_instance . '.' . $instance);

        next if ($self->check_filter(section => 'temperature', instance => $member_instance . '.' . $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Temperature '%s/%s' status is %s [instance: %s].",
                                    $member_name, $result->{eqlMemberHealthDetailsTemperatureName}, $result->{eqlMemberHealthDetailsTemperatureCurrentState},
                                    $member_instance . '.' . $instance
                                    ));
        my $exit = $self->get_severity(section => 'temperature', value => $result->{eqlMemberHealthDetailsTemperatureCurrentState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Temperature '%s/%s' status is %s",
                                                             $member_name, $result->{eqlMemberHealthDetailsTemperatureName}, $result->{eqlMemberHealthDetailsTemperatureCurrentState}));
        }
        
        if (defined($result->{eqlMemberHealthDetailsTemperatureValue})) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{eqlMemberHealthDetailsTemperatureValue});
            if ($checked == 0) {
                my $warn_th = $result->{eqlMemberHealthDetailsTemperatureLowWarningThreshold} . ':' . $result->{eqlMemberHealthDetailsTemperatureHighWarningThreshold};
                my $crit_th = $result->{eqlMemberHealthDetailsTemperatureLowCriticalThreshold} . ':' . $result->{eqlMemberHealthDetailsTemperatureHighCriticalThreshold};
                $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
            }
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Temperature '%s/%s' is %s degree centigrade", $member_name, $result->{eqlMemberHealthDetailsTemperatureName}, $result->{eqlMemberHealthDetailsTemperatureValue}));
            }
            $self->{output}->perfdata_add(
                label => "temp", unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => [$member_name, $instance],
                value => $result->{eqlMemberHealthDetailsTemperatureValue},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
