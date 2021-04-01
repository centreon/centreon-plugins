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

package hardware::server::dell::idrac::snmp::mode::components::amperage;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_probe_status %map_state %map_amperage_type);

my $mapping = {
    amperageProbeStateSettings  => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.30.1.4', map => \%map_state },
    amperageProbeStatus         => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.30.1.5', map => \%map_probe_status },
    amperageProbeReading        => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.30.1.6' },
    amperageProbeType           => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.30.1.7', map => \%map_amperage_type },
    amperageProbeLocationName   => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.30.1.8' },
    amperageProbeUpperCriticalThreshold     => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.30.1.10' },
    amperageProbeUpperNonCriticalThreshold  => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.30.1.11' },
    amperageProbeLowerNonCriticalThreshold  => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.30.1.12' },
    amperageProbeLowerCriticalThreshold     => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.30.1.13' }
};
my $oid_amperageProbeTableEntry = '.1.3.6.1.4.1.674.10892.5.4.600.30.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_amperageProbeTableEntry,
        start => $mapping->{amperageProbeStateSettings}->{oid},
        end => $mapping->{amperageProbeLowerCriticalThreshold}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking amperages");
    $self->{components}->{amperage} = {name => 'amperages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'amperage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_amperageProbeTableEntry}})) {
        next if ($oid !~ /^$mapping->{amperageProbeStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_amperageProbeTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'amperage', instance => $instance));
        $self->{components}->{amperage}->{total}++;

        my ($divisor, $unit) = (1000, 'A');
        if ($result->{amperageProbeType} =~ /amperageProbeTypeIsPowerSupplyAmps|amperageProbeTypeIsSystemAmps/) {
            $divisor = 10;
        } elsif ($result->{amperageProbeType} =~ /amperageProbeTypeIsPowerSupplyWatts|amperageProbeTypeIsSystemWatts/) {
            $unit = 'W';
            $divisor = 1;
        }
        $result->{amperageProbeReading} = (defined($result->{amperageProbeReading})) ? $result->{amperageProbeReading} / $divisor : 'unknown';
        $self->{output}->output_add(
            long_msg => sprintf(
                "amperage '%s' status is '%s' [instance = %s] [state = %s] [value = %s]",
                $result->{amperageProbeLocationName}, $result->{amperageProbeStatus}, $instance, 
                $result->{amperageProbeStateSettings}, $result->{amperageProbeReading}
            )
        );
        
        my $exit = $self->get_severity(label => 'default.state', section => 'amperage.state', value => $result->{amperageProbeStateSettings});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Amperage '%s' state is '%s'", $result->{amperageProbeLocationName}, $result->{amperageProbeStateSettings})
            );
            next;
        }

        $exit = $self->get_severity(label => 'probe.status', section => 'amperage.status', value => $result->{amperageProbeStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Amperage '%s' status is '%s'", $result->{amperageProbeLocationName}, $result->{amperageProbeStatus})
                );
        }
     
        next if ($result->{amperageProbeType} =~ /amperageProbeTypeIsDiscrete/);
        
        if (defined($result->{amperageProbeReading}) && $result->{amperageProbeReading} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'amperage', instance => $instance, value => $result->{amperageProbeReading});
            if ($checked == 0) {
                $result->{amperageProbeLowerNonCriticalThreshold} = (defined($result->{amperageProbeLowerNonCriticalThreshold}) && $result->{amperageProbeLowerNonCriticalThreshold} =~ /[0-9]/) ?
                    $result->{amperageProbeLowerNonCriticalThreshold} / $divisor : '';
                $result->{amperageProbeLowerCriticalThreshold} = (defined($result->{amperageProbeLowerCriticalThreshold}) && $result->{amperageProbeLowerCriticalThreshold} =~ /[0-9]/) ?
                    $result->{amperageProbeLowerCriticalThreshold} / $divisor : '';
                $result->{amperageProbeUpperNonCriticalThreshold} = (defined($result->{amperageProbeUpperNonCriticalThreshold}) && $result->{amperageProbeUpperNonCriticalThreshold} =~ /[0-9]/) ?
                    $result->{amperageProbeUpperNonCriticalThreshold} / $divisor : '';
                $result->{amperageProbeUpperCriticalThreshold} = (defined($result->{amperageProbeUpperCriticalThreshold}) && $result->{amperageProbeUpperCriticalThreshold} =~ /[0-9]/) ?
                    $result->{amperageProbeUpperCriticalThreshold} / $divisor : '';
                my $warn_th = $result->{amperageProbeLowerNonCriticalThreshold} . ':' . $result->{amperageProbeUpperNonCriticalThreshold};
                my $crit_th = $result->{amperageProbeLowerCriticalThreshold} . ':' . $result->{amperageProbeUpperCriticalThreshold};
                $self->{perfdata}->threshold_validate(label => 'warning-amperage-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-amperage-instance-' . $instance, value => $crit_th);
                
                $exit = $self->{perfdata}->threshold_check(
                    value => $result->{amperageProbeReading},
                    threshold => [
                        { label => 'critical-amperage-instance-' . $instance, exit_litteral => 'critical' }, 
                        { label => 'warning-amperage-instance-' . $instance, exit_litteral => 'warning' }
                    ]
                );
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-amperage-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-amperage-instance-' . $instance);
            }
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Amperage '%s' is %s %s", $result->{amperageProbeLocationName}, $result->{amperageProbeReading}, $unit)
                );
            }
            $self->{output}->perfdata_add(
                label => 'amperage', unit => $unit,
                nlabel => 'hardware.probe.amperage.' . ($unit eq 'A' ? 'ampere' : 'watt'),
                instances =>  $result->{amperageProbeLocationName},
                value => $result->{amperageProbeReading},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
