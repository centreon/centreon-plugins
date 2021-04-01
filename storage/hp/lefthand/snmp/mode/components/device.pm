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

package storage::hp::lefthand::snmp::mode::components::device;

use strict;
use warnings;
use storage::hp::lefthand::snmp::mode::components::resources qw($map_status);

my $mapping = {
    storageDeviceSerialNumber           => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.7' },
    storageDeviceTemperature            => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.9' },
    storageDeviceTemperatureCritical    => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.10' },
    storageDeviceTemperatureLimit       => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.11' },
    storageDeviceTemperatureStatus      => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.12', map => $map_status },
    storageDeviceName                   => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.14' },
    storageDeviceSmartHealth            => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.17' }, # normal, marginal, faulty
    storageDeviceState                  => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.90' },
    storageDeviceStatus                 => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1.91', map => $map_status },
};
my $oid_storageDeviceEntry = '.1.3.6.1.4.1.9804.3.1.1.2.4.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_storageDeviceEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking devices");
    $self->{components}->{device} = {name => 'devices', total => 0, skip => 0};
    return if ($self->check_filter(section => 'device'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_storageDeviceEntry}})) {
        next if ($oid !~ /^$mapping->{storageDeviceStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_storageDeviceEntry}, instance => $instance);
        
        if ($result->{storageDeviceState} =~ /off_and_secured|off_or_removed/i) {
            $self->absent_problem(section => 'device', instance => $instance);
            next;
        }
        next if ($self->check_filter(section => 'device', instance => $instance));
        
        $self->{components}->{device}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("storage device '%s' status is '%s' [instance = %s, state = %s, serial = %s, smart health = %s]",
                                    $result->{storageDeviceName}, $result->{storageDeviceStatus}, $instance, $result->{storageDeviceState},
                                    $result->{storageDeviceSerialNumber}, $result->{storageDeviceSmartHealth}));
        
        my $exit = $self->get_severity(label => 'default', section => 'device', value => $result->{storageDeviceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("storage device '%s' state is '%s'", $result->{storageDeviceName}, $result->{storageDeviceState}));
        }
        
        $exit = $self->get_severity(label => 'smart', section => 'device.smart', value => $result->{storageDeviceSmartHealth});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("storage device '%s' smart health state is '%s'", $result->{storageDeviceName}, $result->{storageDeviceSmartHealth}));
        }
        
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'device.temperature', instance => $instance, value => $result->{storageDeviceTemperature});
        if ($checked == 0) {
            my $warn_th = '';
            my $crit_th = defined($result->{storageDeviceTemperatureCritical}) ? $result->{storageDeviceTemperatureCritical} : '';
            $self->{perfdata}->threshold_validate(label => 'warning-device.temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-device.temperature-instance-' . $instance, value => $crit_th);
            
            $exit = $self->{perfdata}->threshold_check(
                value => $result->{storageDeviceTemperature}, 
                threshold => [ { label => 'critical-device.temperature-instance-' . $instance, exit_litteral => 'critical' }, 
                               { label => 'warning-device.temperature-instance-' . $instance, exit_litteral => 'warning' } ]);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-device.temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-device.temperature-instance-' . $instance)
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("storage device '%s' temperature is %s C", $result->{storageDeviceName}, $result->{storageDeviceTemperature}));
        }
        $self->{output}->perfdata_add(
            label => 'temp', unit => 'C',
            nlabel => 'hardware.device.temperature.celsius',
            instances => $result->{storageDeviceName},
            value => $result->{storageDeviceTemperature},
            warning => $warn,
            critical => $crit,
            max => $result->{storageDeviceTemperatureLimit},
        );
    }
}

1;
