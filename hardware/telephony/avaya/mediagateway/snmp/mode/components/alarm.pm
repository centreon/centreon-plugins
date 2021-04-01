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

package hardware::telephony::avaya::mediagateway::snmp::mode::components::alarm;

use strict;
use warnings;

sub load {}

my $bits_alarm = {
    23 => 'at least two fans have been operating at less than 90% of their nominal speed for 5 minutes or more',
    22 => 'the power supply fan has been operating at less than 90% of its nominal speed for 10 minutes or more, but less than 15 minutes',
    21 => 'the power supply fan has been operating at less than 90% of its nominal speed for 15 minutes or more',
    19 => 'cmgCpuTemp has exceeded its warning threshold',
    18 => 'mgDspTemp has exceeded its warning threshold',
    16 => 'Power On Status Test failure -NCE, QUICC test failures on power up',
    15 => 'The +5.1 v power supply to the MG processor is out of range',
    14 => 'The +3.3 v power supply to the VoIP complexes is out of range',
    13 => 'The +3.3 v power supply to the VoIP complexes is out of range',
    12 => 'The +1.58 v power supply to the DSP units is out of range',
    11 => 'The +2.5 v power supply to the 8260 processor is out of range',
    10 => 'The -48 v auxiliary power supply to the endpoints is out of range',
    9 => 'The +12 v power supply to the fans is out of range',
    7 => 'Clock synchronization signal is lost',
    6 => 'Clock synchronization signal warning. Only one clock syncronization signal source remains',
    5 => 'Clock synchronization signal excessive switching',
    4 => 'TDM Test Expansion Box 1 Failure',
    3 => 'TDM Test Expansion Box 2 Failure',
    2 => 'PoE Power Supply Base Box Failure',
    1 => 'PoE Power Supply Expansion Box 1 Failure',
    0 => 'PoE Power Supply Expansion Box 2 Failure',
};

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking alarms");
    $self->{components}->{alarm} = { name => 'alarms', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'alarm'));

    my $oid_cmgHardwareFaultMask = '.1.3.6.1.4.1.6889.2.9.1.1.10.12.0';
    return if (!defined($self->{results}->{$oid_cmgHardwareFaultMask}));

    $self->{results}->{$oid_cmgHardwareFaultMask} = oct("0b" . unpack('B*', $self->{results}->{$oid_cmgHardwareFaultMask}));
    foreach (sort { $a <=> $b }  keys %$bits_alarm) {
        my $instance = $_;
        my $status = 'disabled';
        if (($self->{results}->{$oid_cmgHardwareFaultMask} & (1 << $_))) {
            $status = 'enabled';
        }

        next if ($self->check_filter(section => 'alarm', instance => $instance));
        $self->{components}->{alarm}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "alarm '%s' status is '%s' [instance: %s]",
                $bits_alarm->{$_}, $status, $instance
            )
        );
        my $exit = $self->get_severity(section => 'alarm', instance => $instance, value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Alarm '%s' status is '%s'",
                                                             $bits_alarm->{$_}, $status));
        }
    }
}

1;
