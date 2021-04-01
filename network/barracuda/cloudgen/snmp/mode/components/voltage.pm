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

package network::barracuda::cloudgen::snmp::mode::components::voltage;

use strict;
use warnings;

my $mapping = {
    hwSensorName            => { oid => '.1.3.6.1.4.1.10704.1.4.1.1' },
    hwSensorType            => { oid => '.1.3.6.1.4.1.10704.1.4.1.2' },
    hwSensorValue           => { oid => '.1.3.6.1.4.1.10704.1.4.1.3' },
};
my $oid_HwSensorsEntry = '.1.3.6.1.4.1.10704.1.4.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_HwSensorsEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_HwSensorsEntry}})) {
        next if ($oid !~ /^$mapping->{hwSensorType}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_HwSensorsEntry}, instance => $instance);

        next if ($self->check_filter(section => 'voltage', instance => $instance));
        next if ($result->{hwSensorType} != 0); #Voltages
        $self->{components}->{voltage}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Voltage '%s' is '%s' mV",
                                    $result->{hwSensorName}, $result->{hwSensorValue}));
   
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{hwSensorValue});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s' is '%s' mV", $result->{hwSensorName}, $result->{hwSensorValue}));
        }
        
        $self->{output}->perfdata_add(
            label => 'voltage', unit => 'mV',
            nlabel => 'hardware.voltage.millivolt',
            instances => $result->{hwSensorName},
            value => $result->{hwSensorValue},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
