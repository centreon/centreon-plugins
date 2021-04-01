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

package network::perle::ids::snmp::mode::components::temperature;

use strict;
use warnings;
use network::perle::ids::snmp::mode::components::resources qw($map_status);

my $mapping = {
    perleEnvMonTemperatureStatusDescr  => { oid => '.1.3.6.1.4.1.1966.22.12.1.2.1.2' },
    perleEnvMonTemperatureStatusValue  => { oid => '.1.3.6.1.4.1.1966.22.12.1.2.1.3' },
    perleEnvMonTemperatureState        => { oid => '.1.3.6.1.4.1.1966.22.12.1.2.1.5', map => $map_status },
};
my $oid_perleEnvMonTemperatureStatusEntry = '.1.3.6.1.4.1.1966.22.12.1.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_perleEnvMonTemperatureStatusEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_perleEnvMonTemperatureStatusEntry}})) {
        next if ($oid !~ /^$mapping->{perleEnvMonTemperatureState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_perleEnvMonTemperatureStatusEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance, name => $result->{perleEnvMonTemperatureStatusDescr}));
        next if ($result->{perleEnvMonTemperatureState} =~ /notPresent/i &&
                 $self->absent_problem(section => 'temperature', instance => $instance, name => $result->{perleEnvMonTemperatureStatusDescr}));
        
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s, value = %s]",
                                                        $result->{perleEnvMonTemperatureStatusDescr}, $result->{perleEnvMonTemperatureState}, $instance, 
                                                        $result->{perleEnvMonTemperatureStatusValue}));
        $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{perleEnvMonTemperatureState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $result->{perleEnvMonTemperatureStatusDescr}, $result->{perleEnvMonTemperatureState}));
        }
        
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, name => $result->{perleEnvMonTemperatureStatusDescr}, value => $result->{perleEnvMonTemperatureStatusValue});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' is '%s' C", $result->{perleEnvMonTemperatureStatusDescr}, $result->{perleEnvMonTemperatureStatusValue}));
        }
        $self->{output}->perfdata_add(
            label => 'temperature', unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $result->{perleEnvMonTemperatureStatusDescr},
            value => $result->{perleEnvMonTemperatureStatusValue},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
