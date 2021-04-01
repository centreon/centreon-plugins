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

package storage::hp::lefthand::snmp::mode::components::temperature;

use strict;
use warnings;
use storage::hp::lefthand::snmp::mode::components::resources qw($map_status);

my $mapping = {
    infoTemperatureSensorName       => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.121.1.2' },
    infoTemperatureSensorValue      => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.121.1.3' },
    infoTemperatureSensorCritical   => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.121.1.4' },
    infoTemperatureSensorLimit      => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.121.1.5' },
    infoTemperatureSensorState      => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.121.1.90' },
    infoTemperatureSensorStatus     => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.121.1.91', map => $map_status },
};
my $oid_infoTemperatureSensorEntry = '.1.3.6.1.4.1.9804.3.1.1.2.1.121.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_infoTemperatureSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperature sensors");
    $self->{components}->{temperature} = {name => 'temperature sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_infoTemperatureSensorEntry}})) {
        next if ($oid !~ /^$mapping->{infoTemperatureSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_infoTemperatureSensorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("temperature sensor '%s' status is '%s' [instance = %s, state = %s, temperature = %s]",
                                    $result->{infoTemperatureSensorName}, $result->{infoTemperatureSensorStatus}, $instance, $result->{infoTemperatureSensorState},
                                    defined($result->{infoTemperatureSensorValue}) ? $result->{infoTemperatureSensorValue} : '-'));
        
        my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{infoTemperatureSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("temperature sensor '%s' state is '%s'", $result->{infoTemperatureSensorName}, $result->{infoTemperatureSensorState}));
        }        
        
        next if (!defined($result->{infoTemperatureSensorValue}) || $result->{infoTemperatureSensorValue} !~ /[0-9]/);
        
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{infoTemperatureSensorValue});
        if ($checked == 0) {
            my $warn_th = '';
            my $crit_th = defined($result->{infoTemperatureSensorCritical}) ? $result->{infoTemperatureSensorCritical} : '';
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
            
            $exit = $self->{perfdata}->threshold_check(
                value => $result->{infoTemperatureSensorValue}, 
                threshold => [ { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' }, 
                               { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' } ]);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance)
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("temperature sensor '%s' is %s C", $result->{infoTemperatureSensorName}, $result->{infoTemperatureSensorValue}));
        }
        $self->{output}->perfdata_add(
            label => 'temp', unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $result->{infoTemperatureSensorName},
            value => $result->{infoTemperatureSensorValue},
            warning => $warn,
            critical => $crit,
            max => $result->{infoTemperatureSensorLimit}
        );
    }
}

1;
