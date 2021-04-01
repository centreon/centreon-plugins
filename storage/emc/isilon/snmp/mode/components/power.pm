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

package storage::emc::isilon::snmp::mode::components::power;

use strict;
use warnings;

my $mapping = {
    powerSensorName          => { oid => '.1.3.6.1.4.1.12124.2.55.1.2' },
    powerSensorDescription   => { oid => '.1.3.6.1.4.1.12124.2.55.1.3' },
    powerSensorValue         => { oid => '.1.3.6.1.4.1.12124.2.55.1.4' },
};

my $oid_powerSensorEntry = '.1.3.6.1.4.1.12124.2.55.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_powerSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power");
    $self->{components}->{power} = {name => 'power', total => 0, skip => 0};
    return if ($self->check_filter(section => 'power'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_powerSensorEntry}})) {
        next if ($oid !~ /^$mapping->{powerSensorValue}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_powerSensorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'power', instance => $instance));
        $self->{components}->{power}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power '%s' sensor is %s [instance = %s] [description = %s]",
                                    $result->{powerSensorName}, $result->{powerSensorValue}, $instance, 
                                    $result->{powerSensorDescription}));
             
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{powerSensorValue});
        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power '%s' sensor is %s (Volt or Amp)", $result->{powerSensorName}, $result->{powerSensorValue}));
        }
        $self->{output}->perfdata_add(
            label => 'power',
            nlabel => 'hardware.power.sensor.count',
            instances => $result->{powerSensorName}, 
            value => $result->{powerSensorValue},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
