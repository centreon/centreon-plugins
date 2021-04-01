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

package network::checkpoint::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_states_temperature = (
    0 => 'false',
    1 => 'true',
    2 => 'reading error',
);

my $mapping = {
    tempertureSensorName => { oid => '.1.3.6.1.4.1.2620.1.6.7.8.1.1.2' },
    tempertureSensorValue => { oid => '.1.3.6.1.4.1.2620.1.6.7.8.1.1.3' },
    tempertureSensorStatus => { oid => '.1.3.6.1.4.1.2620.1.6.7.8.1.1.6', map => \%map_states_temperature },
};
my $oid_tempertureSensorEntry = '.1.3.6.1.4.1.2620.1.6.7.8.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_tempertureSensorEntry, start => $mapping->{tempertureSensorName}->{oid}, end => $mapping->{tempertureSensorStatus}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
   
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_tempertureSensorEntry}})) {
        next if ($oid !~ /^$mapping->{tempertureSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_tempertureSensorEntry}, instance => $instance);

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        next if ($result->{tempertureSensorName} !~ /^[0-9a-zA-Z ]+$/); # sometimes there is some wrong values in hex 
    	
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' sensor out of range status is '%s' [instance: %s]",
                                        $result->{tempertureSensorName}, $result->{tempertureSensorStatus}, $instance));
        my $exit = $self->get_severity(section => 'temperature', value => $result->{tempertureSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s/%s' sensor out of range status is '%s'", $result->{tempertureSensorName}, $instance, $result->{tempertureSensorStatus}));
        }

        if (defined($result->{tempertureSensorValue}) && $result->{tempertureSensorValue} =~ /^[0-9\.]+$/) {
            $self->{output}->perfdata_add(
                label => 'temp', unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => [$result->{tempertureSensorName}, $instance],
                value => sprintf("%.2f", $result->{tempertureSensorValue})
            );
        }
    }
}

1;
