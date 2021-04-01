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

package hardware::server::dell::idrac::snmp::mode::components::temperature;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_probe_status %map_state);

my %map_temp_type = (
    1 => 'temperatureProbeTypeIsOther', 
    2 => 'temperatureProbeTypeIsUnknown', 
    3 => 'temperatureProbeTypeIsAmbientESM', 
    16 => 'temperatureProbeTypeIsDiscrete'
);

my $mapping = {
    temperatureProbeStateSettings => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.4', map => \%map_state },
    temperatureProbeStatus => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.5', map => \%map_probe_status },
    temperatureProbeReading => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.6' },
    temperatureProbeType => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.7', map => \%map_temp_type },
    temperatureProbeLocationName => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.8' },
    temperatureProbeUpperCriticalThreshold => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.10' },
    temperatureProbeUpperNonCriticalThreshold => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.11' },
    temperatureProbeLowerNonCriticalThreshold => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.12' },
    temperatureProbeLowerCriticalThreshold => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.13' }
};
my $oid_temperatureProbeTableEntry = '.1.3.6.1.4.1.674.10892.5.4.700.20.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_temperatureProbeTableEntry,
        start => $mapping->{temperatureProbeStateSettings}->{oid},
        end => $mapping->{temperatureProbeLowerCriticalThreshold}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_temperatureProbeTableEntry}})) {
        next if ($oid !~ /^$mapping->{temperatureProbeStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_temperatureProbeTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $result->{temperatureProbeReading} = (defined($result->{temperatureProbeReading})) ? $result->{temperatureProbeReading} / 10 : 'unknown';
        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' status is '%s' [instance = %s] [state = %s] [value = %s]",
                $result->{temperatureProbeLocationName}, $result->{temperatureProbeStatus}, $instance, 
                $result->{temperatureProbeStateSettings}, $result->{temperatureProbeReading}
            )
        );

        my $exit = $self->get_severity(label => 'default.state', section => 'temperature.state', value => $result->{temperatureProbeStateSettings});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Temperature '%s' state is '%s'", $result->{temperatureProbeLocationName}, $result->{temperatureProbeStateSettings}
                )
            );
            next;
        }

        $exit = $self->get_severity(label => 'probe.status', section => 'temperature.status', value => $result->{temperatureProbeStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Temperature '%s' status is '%s'", $result->{temperatureProbeLocationName}, $result->{temperatureProbeStatus}
                )
            );
        }
     
        if (defined($result->{temperatureProbeReading}) && $result->{temperatureProbeReading} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{temperatureProbeReading});
            if ($checked == 0) {
                $result->{temperatureProbeLowerNonCriticalThreshold} = (defined($result->{temperatureProbeLowerNonCriticalThreshold}) && $result->{temperatureProbeLowerNonCriticalThreshold} =~ /[0-9]/) ?
                    $result->{temperatureProbeLowerNonCriticalThreshold} / 10 : '';
                $result->{temperatureProbeLowerCriticalThreshold} = (defined($result->{temperatureProbeLowerCriticalThreshold}) && $result->{temperatureProbeLowerCriticalThreshold} =~ /[0-9]/) ?
                    $result->{temperatureProbeLowerCriticalThreshold} / 10 : '';
                $result->{temperatureProbeUpperNonCriticalThreshold} = (defined($result->{temperatureProbeUpperNonCriticalThreshold}) && $result->{temperatureProbeUpperNonCriticalThreshold} =~ /[0-9]/) ?
                    $result->{temperatureProbeUpperNonCriticalThreshold} / 10 : '';
                $result->{temperatureProbeUpperCriticalThreshold} = (defined($result->{temperatureProbeUpperCriticalThreshold}) && $result->{temperatureProbeUpperCriticalThreshold} =~ /[0-9]/) ?
                    $result->{temperatureProbeUpperCriticalThreshold} / 10 : '';
                my $warn_th = $result->{temperatureProbeLowerNonCriticalThreshold} . ':' . $result->{temperatureProbeUpperNonCriticalThreshold};
                my $crit_th = $result->{temperatureProbeLowerCriticalThreshold} . ':' . $result->{temperatureProbeUpperCriticalThreshold};
                $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
                
                $exit = $self->{perfdata}->threshold_check(
                    value => $result->{temperatureProbeReading},
                    threshold => [
                        { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' }, 
                        { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' }
                    ]
                );
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
            }

            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Temperature '%s' is %s degree centigrade", $result->{temperatureProbeLocationName}, $result->{temperatureProbeReading}
                    )
                );
            }
            $self->{output}->perfdata_add(
                label => 'temp', unit => 'C',
                nlabel => 'hardware.probe.temperature.celsius',
                instances => $result->{temperatureProbeLocationName},
                value => $result->{temperatureProbeReading},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
