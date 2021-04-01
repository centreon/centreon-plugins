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

package centreon::common::adic::tape::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_status = (
    1 => 'nominal', 
    2 => 'warningLow', 3 => 'warningHigh',
    4 => 'alarmLow', 5 => 'alarmHigh', 
    6 => 'notInstalled', 7 => 'noData',
);

my $mapping = {
    temperatureSensorName => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.30.1.2' },
    temperatureSensorStatus => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.30.1.3', map => \%map_status },
    temperatureSensorDegreesCelsius => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.30.1.4' },
    temperatureSensorWarningHi => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.30.1.8' },
    temperatureSensorNominalHi => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.30.1.6' },
    temperatureSensorNominalLo => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.30.1.5' },
    temperatureSensorWarningLo => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.30.1.7' },
    temperatureSensorLocation => { oid => '.1.3.6.1.4.1.3764.1.1.200.200.30.1.9' },
};
my $oid_temperatureSensorEntry = '.1.3.6.1.4.1.3764.1.1.200.200.30.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_temperatureSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_temperatureSensorEntry}})) {
        next if ($oid !~ /^$mapping->{temperatureSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_temperatureSensorEntry}, instance => $instance);
        
        $result->{temperatureSensorName} =~ s/\s+/ /g;
        $result->{temperatureSensorName} = centreon::plugins::misc::trim($result->{temperatureSensorName});
        $result->{temperatureSensorLocation} =~ s/,/_/g;
        my $id = $result->{temperatureSensorName} . '_' . $result->{temperatureSensorLocation};
        
        next if ($self->check_filter(section => 'temperature', instance => $id));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s] [value = %s]",
                                    $id, $result->{temperatureSensorStatus}, $id, 
                                    $result->{temperatureSensorDegreesCelsius}));
        
        my $exit = $self->get_severity(label => 'sensor', section => 'temperature', value => $result->{temperatureSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $id, $result->{temperatureSensorStatus}));
            next;
        }
     
        if (defined($result->{temperatureSensorDegreesCelsius}) && $result->{temperatureSensorDegreesCelsius} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{temperatureSensorDegreesCelsius});
            if ($checked == 0) {
                $result->{temperatureSensorNominalLo} = (defined($result->{temperatureSensorNominalLo}) && $result->{temperatureSensorNominalLo} =~ /[0-9]/) ?
                    $result->{temperatureSensorNominalLo} : '';
                $result->{temperatureSensorWarningLo} = (defined($result->{temperatureSensorWarningLo}) && $result->{temperatureSensorWarningLo} =~ /[0-9]/) ?
                    $result->{temperatureSensorWarningLo} : '';
                $result->{temperatureSensorNominalHi} = (defined($result->{temperatureSensorNominalHi}) && $result->{temperatureSensorNominalHi} =~ /[0-9]/) ?
                    $result->{temperatureSensorNominalHi} : '';
                $result->{temperatureSensorWarningHi} = (defined($result->{temperatureSensorWarningHi}) && $result->{temperatureSensorWarningHi} =~ /[0-9]/) ?
                    $result->{temperatureSensorWarningHi} : '';
                my $warn_th = $result->{temperatureSensorNominalLo} . ':' . $result->{temperatureSensorNominalHi};
                my $crit_th = $result->{temperatureSensorWarningLo} . ':' . $result->{temperatureSensorWarningHi};
                $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
                
                $exit = $self->{perfdata}->threshold_check(value => $result->{temperatureSensorDegreesCelsius}, threshold => [ { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' }, 
                                                                                                                     { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' } ]);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
            }
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Temperature '%s' is %s degree centigrade", $id, $result->{temperatureSensorDegreesCelsius}));
            }
            $self->{output}->perfdata_add(
                label => 'temp', unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => $id,
                value => $result->{temperatureSensorDegreesCelsius},
                warning => $warn,
                critical => $crit,
            );
        }
    }
}

1;
