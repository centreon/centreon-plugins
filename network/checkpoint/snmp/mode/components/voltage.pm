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

package network::checkpoint::snmp::mode::components::voltage;

use strict;
use warnings;
 
my %map_states_voltage = (
    0 => 'false',
    1 => 'true',
    2 => 'reading error',
);

my $mapping = {
    voltageSensorName => { oid => '.1.3.6.1.4.1.2620.1.6.7.8.3.1.2' },
    voltageSensorValue => { oid => '.1.3.6.1.4.1.2620.1.6.7.8.3.1.3' },
    voltageSensorStatus => { oid => '.1.3.6.1.4.1.2620.1.6.7.8.3.1.6', map => \%map_states_voltage },
};
my $oid_voltageSensorEntry = '.1.3.6.1.4.1.2620.1.6.7.8.3.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_voltageSensorEntry, start => $mapping->{voltageSensorName}->{oid}, end => $mapping->{voltageSensorStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_voltageSensorEntry}})) {
        next if ($oid !~ /^$mapping->{voltageSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_voltageSensorEntry}, instance => $instance);
    
        next if ($self->check_filter(section => 'voltage', instance => $instance));
        next if ($result->{voltageSensorName} !~ /^[0-9a-zA-Z ]+$/); # sometimes there is some wrong values in hex 
     
        $self->{components}->{voltage}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Voltage '%s' sensor out of range status is '%s' [instance: %s]",
                                        $result->{voltageSensorName}, $result->{voltageSensorStatus}, $instance));
        my $exit = $self->get_severity(section => 'voltage', value => $result->{voltageSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s/%s' sensor out of range status is '%s'", $result->{voltageSensorName}, $instance, $result->{voltageSensorStatus}));
        }
        
        if (defined($result->{voltageSensorValue}) && $result->{voltageSensorValue} =~ /^[0-9\.]+$/) {
            $self->{output}->perfdata_add(
                label => 'volt', unit => 'V',
                nlabel => 'hardware.voltage.volt',
                instances => [$result->{voltageSensorName}, $instance],
                value => sprintf("%.2f", $result->{voltageSensorValue})
            );
        }
    }
}

1;
