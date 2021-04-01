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

package hardware::server::dell::idrac::snmp::mode::components::coolingdevice;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_probe_status %map_state);

my $mapping = {
    coolingDeviceStateSettings  => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.12.1.4', map => \%map_state },
    coolingDeviceStatus         => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.12.1.5', map => \%map_probe_status },
    coolingDeviceReading        => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.12.1.6' },
    coolingDeviceLocationName   => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.12.1.8' },
    coolingDeviceUpperCriticalThreshold     => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.10' },
    coolingDeviceUpperNonCriticalThreshold  => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.11' },
    coolingDeviceLowerNonCriticalThreshold  => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.20.1.12' },
    coolingDeviceLowerCriticalThreshold     => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.12.1.13' }
};
my $oid_coolingDeviceTableEntry = '.1.3.6.1.4.1.674.10892.5.4.700.12.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_coolingDeviceTableEntry,
        start => $mapping->{coolingDeviceStateSettings}->{oid},
        end => $mapping->{coolingDeviceLowerCriticalThreshold}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cooling devices");
    $self->{components}->{coolingdevice} = {name => 'cooling devices', total => 0, skip => 0};
    return if ($self->check_filter(section => 'coolingdevice'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_coolingDeviceTableEntry}})) {
        next if ($oid !~ /^$mapping->{coolingDeviceStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_coolingDeviceTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'coolingdevice', instance => $instance));
        $self->{components}->{coolingdevice}->{total}++;

        $result->{coolingDeviceReading} = (defined($result->{coolingDeviceReading})) ? $result->{coolingDeviceReading} : 'unknown';
        $self->{output}->output_add(
            long_msg => sprintf(
                "cooling device '%s' status is '%s' [instance = %s] [state = %s] [value = %s]",
                $result->{coolingDeviceLocationName}, $result->{coolingDeviceStatus}, $instance, 
                $result->{coolingDeviceStateSettings}, $result->{coolingDeviceReading}
            )
        );

        my $exit = $self->get_severity(label => 'default.state', section => 'coolingdevice.state', value => $result->{coolingDeviceStateSettings});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Cooling device '%s' state is '%s'", $result->{coolingDeviceLocationName}, $result->{coolingDeviceStateSettings}));
            next;
        }

        $exit = $self->get_severity(label => 'probe.status', section => 'coolingdevice.status', value => $result->{coolingDeviceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Cooling device '%s' status is '%s'", $result->{coolingDeviceLocationName}, $result->{coolingDeviceStatus})
            );
        }
     
        if (defined($result->{coolingDeviceReading}) && $result->{coolingDeviceReading} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'coolingdevice', instance => $instance, value => $result->{coolingDeviceReading});
            if ($checked == 0) {
                $result->{coolingDeviceLowerNonCriticalThreshold} = (defined($result->{coolingDeviceLowerNonCriticalThreshold}) && $result->{coolingDeviceLowerNonCriticalThreshold} =~ /[0-9]/) ?
                    $result->{coolingDeviceLowerNonCriticalThreshold} / 10 : '';
                $result->{coolingDeviceLowerCriticalThreshold} = (defined($result->{coolingDeviceLowerCriticalThreshold}) && $result->{coolingDeviceLowerCriticalThreshold} =~ /[0-9]/) ?
                    $result->{coolingDeviceLowerCriticalThreshold} / 10 : '';
                $result->{coolingDeviceUpperNonCriticalThreshold} = (defined($result->{coolingDeviceUpperNonCriticalThreshold}) && $result->{coolingDeviceUpperNonCriticalThreshold} =~ /[0-9]/) ?
                    $result->{coolingDeviceUpperNonCriticalThreshold} / 10 : '';
                $result->{coolingDeviceUpperCriticalThreshold} = (defined($result->{coolingDeviceUpperCriticalThreshold}) && $result->{coolingDeviceUpperCriticalThreshold} =~ /[0-9]/) ?
                    $result->{coolingDeviceUpperCriticalThreshold} : '';
                my $warn_th = $result->{coolingDeviceLowerNonCriticalThreshold} . ':' . $result->{coolingDeviceUpperNonCriticalThreshold};
                my $crit_th = $result->{coolingDeviceLowerCriticalThreshold} . ':' . $result->{coolingDeviceUpperCriticalThreshold};
                $self->{perfdata}->threshold_validate(label => 'warning-coolingdevice-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-coolingdevice-instance-' . $instance, value => $crit_th);
                
                $exit = $self->{perfdata}->threshold_check(
                    value => $result->{coolingDeviceReading},
                    threshold => [
                        { label => 'critical-coolingdevice-instance-' . $instance, exit_litteral => 'critical' }, 
                        { label => 'warning-coolingdevice-instance-' . $instance, exit_litteral => 'warning' }
                    ]
                );
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-coolingdevice-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-coolingdevice-instance-' . $instance);
            }
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Cooling device '%s' is %s rpm", $result->{coolingDeviceLocationName}, $result->{coolingDeviceReading})
                );
            }
            $self->{output}->perfdata_add(
                label => 'fan', unit => 'rpm',
                nlabel => 'hardware.fan.speed.rpm',
                instances => $result->{coolingDeviceLocationName},
                value => $result->{coolingDeviceReading},
                warning => $warn,
                critical => $crit,
            );
        }
    }
}

1;
