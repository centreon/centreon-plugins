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

package hardware::server::dell::idrac::snmp::mode::components::voltage;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_probe_status %map_state);

my $mapping = {
    voltageProbeStateSettings   => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.20.1.4', map => \%map_state },
    voltageProbeStatus          => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.20.1.5', map => \%map_probe_status },
    voltageProbeReading         => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.20.1.6' },
    voltageProbeLocationName    => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.20.1.8' },
    voltageProbeUpperCriticalThreshold      => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.20.1.10' },
    voltageProbeUpperNonCriticalThreshold   => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.20.1.11' },
    voltageProbeLowerNonCriticalThreshold   => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.20.1.12' },
    voltageProbeLowerCriticalThreshold      => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.20.1.13' }
};
my $oid_voltageProbeTableEntry = '.1.3.6.1.4.1.674.10892.5.4.600.20.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_voltageProbeTableEntry,
        start => $mapping->{voltageProbeStateSettings}->{oid},
        end => $mapping->{voltageProbeLowerCriticalThreshold}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_voltageProbeTableEntry}})) {
        next if ($oid !~ /^$mapping->{voltageProbeStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_voltageProbeTableEntry}, instance => $instance);

        next if ($self->check_filter(section => 'voltage', instance => $instance));
        $self->{components}->{voltage}->{total}++;

        $result->{voltageProbeReading} = (defined($result->{voltageProbeReading})) ? $result->{voltageProbeReading} / 1000 : 'unknown';
        $self->{output}->output_add(
            long_msg => sprintf(
                "voltage '%s' status is '%s' [instance = %s] [state = %s] [value = %s]",
                $result->{voltageProbeLocationName}, $result->{voltageProbeStatus}, $instance, 
                $result->{voltageProbeStateSettings}, $result->{voltageProbeReading}
            )
        );

        my $exit = $self->get_severity(label => 'default.state', section => 'voltage.state', value => $result->{voltageProbeStateSettings});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Voltage '%s' state is '%s'", $result->{voltageProbeLocationName}, $result->{voltageProbeStateSettings}
                )
            );
            next;
        }

        $exit = $self->get_severity(label => 'probe.status', section => 'voltage.status', value => $result->{voltageProbeStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Voltage '%s' status is '%s'", $result->{voltageProbeLocationName}, $result->{voltageProbeStatus}
                )
            );
        }
     
        if (defined($result->{voltageProbeReading}) && $result->{voltageProbeReading} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{voltageProbeReading});
            if ($checked == 0) {
                $result->{voltageProbeLowerNonCriticalThreshold} = (defined($result->{voltageProbeLowerNonCriticalThreshold}) && $result->{voltageProbeLowerNonCriticalThreshold} =~ /[0-9]/) ?
                    $result->{voltageProbeLowerNonCriticalThreshold} / 1000 : '';
                $result->{voltageProbeLowerCriticalThreshold} = (defined($result->{voltageProbeLowerCriticalThreshold}) && $result->{voltageProbeLowerCriticalThreshold} =~ /[0-9]/) ?
                    $result->{voltageProbeLowerCriticalThreshold} / 1000 : '';
                $result->{voltageProbeUpperNonCriticalThreshold} = (defined($result->{voltageProbeUpperNonCriticalThreshold}) && $result->{voltageProbeUpperNonCriticalThreshold} =~ /[0-9]/) ?
                    $result->{voltageProbeUpperNonCriticalThreshold} / 1000 : '';
                $result->{voltageProbeUpperCriticalThreshold} = (defined($result->{voltageProbeUpperCriticalThreshold}) && $result->{voltageProbeUpperCriticalThreshold} =~ /[0-9]/) ?
                    $result->{voltageProbeUpperCriticalThreshold} / 1000 : '';
                my $warn_th = $result->{voltageProbeLowerNonCriticalThreshold} . ':' . $result->{voltageProbeUpperNonCriticalThreshold};
                my $crit_th = $result->{voltageProbeLowerCriticalThreshold} . ':' . $result->{voltageProbeUpperCriticalThreshold};
                $self->{perfdata}->threshold_validate(label => 'warning-voltage-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-voltage-instance-' . $instance, value => $crit_th);

                $exit = $self->{perfdata}->threshold_check(
                    value => $result->{voltageProbeReading},
                    threshold => [
                        { label => 'critical-voltage-instance-' . $instance, exit_litteral => 'critical' }, 
                        { label => 'warning-voltage-instance-' . $instance, exit_litteral => 'warning' }
                    ]
                );
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-voltage-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-voltage-instance-' . $instance);
            }

            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Voltage '%s' is %s V", $result->{voltageProbeLocationName}, $result->{voltageProbeReading}
                    )
                );
            }
            $self->{output}->perfdata_add(
                label => 'voltage', unit => 'V',
                nlabel => 'hardware.probe.voltage.volt',
                instances => $result->{voltageProbeLocationName},
                value => $result->{voltageProbeReading},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
