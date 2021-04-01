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

package network::acmepacket::snmp::mode::components::temperature;

use strict;
use warnings;
use network::acmepacket::snmp::mode::components::resources qw($map_status);

my $mapping = {
    apEnvMonTemperatureStatusDescr  => { oid => '.1.3.6.1.4.1.9148.3.3.1.3.1.1.3' },
    apEnvMonTemperatureStatusValue  => { oid => '.1.3.6.1.4.1.9148.3.3.1.3.1.1.4' },
    apEnvMonTemperatureState        => { oid => '.1.3.6.1.4.1.9148.3.3.1.3.1.1.5', map => $map_status },
};
my $oid_apEnvMonTemperatureStatusEntry = '.1.3.6.1.4.1.9148.3.3.1.3.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_apEnvMonTemperatureStatusEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_apEnvMonTemperatureStatusEntry}})) {
        next if ($oid !~ /^$mapping->{apEnvMonTemperatureState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_apEnvMonTemperatureStatusEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        next if ($result->{apEnvMonTemperatureState} =~ /notPresent/i &&
                 $self->absent_problem(section => 'temperature', instance => $instance));
        
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s, value = %s]",
                                                        $result->{apEnvMonTemperatureStatusDescr}, $result->{apEnvMonTemperatureState}, $instance, 
                                                        $result->{apEnvMonTemperatureStatusValue}));
        $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{apEnvMonTemperatureState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $result->{apEnvMonTemperatureStatusDescr}, $result->{apEnvMonTemperatureState}));
        }
        
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{apEnvMonTemperatureStatusValue});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' is '%s' C", $result->{apEnvMonTemperatureStatusDescr}, $result->{apEnvMonTemperatureStatusValue}));
        }
        $self->{output}->perfdata_add(
            label => 'temperature', unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $result->{apEnvMonTemperatureStatusDescr},
            value => $result->{apEnvMonTemperatureStatusValue},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
