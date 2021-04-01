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

package network::acmepacket::snmp::mode::components::voltage;

use strict;
use warnings;
use network::acmepacket::snmp::mode::components::resources qw($map_status);

my $mapping = {
    apEnvMonVoltageStatusDescr  => { oid => '.1.3.6.1.4.1.9148.3.3.1.2.1.1.3' },
    apEnvMonVoltageStatusValue  => { oid => '.1.3.6.1.4.1.9148.3.3.1.2.1.1.4' },
    apEnvMonVoltageState        => { oid => '.1.3.6.1.4.1.9148.3.3.1.2.1.1.5', map => $map_status },
};
my $oid_apEnvMonVoltageStatusEntry = '.1.3.6.1.4.1.9148.3.3.1.2.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_apEnvMonVoltageStatusEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_apEnvMonVoltageStatusEntry}})) {
        next if ($oid !~ /^$mapping->{apEnvMonVoltageState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_apEnvMonVoltageStatusEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'voltage', instance => $instance));
        next if ($result->{apEnvMonVoltageState} =~ /notPresent/i &&
                 $self->absent_problem(section => 'voltage', instance => $instance));
        
        $result->{apEnvMonVoltageStatusValue} = sprintf("%.3f", $result->{apEnvMonVoltageStatusValue});
        $self->{components}->{voltage}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("voltage '%s' status is '%s' [instance = %s, value = %s]",
                                                        $result->{apEnvMonVoltageStatusDescr}, $result->{apEnvMonVoltageState}, $instance, 
                                                        $result->{apEnvMonVoltageStatusValue}));
        $exit = $self->get_severity(label => 'default', section => 'voltage', value => $result->{apEnvMonVoltageState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s' status is '%s'", $result->{apEnvMonVoltageStatusDescr}, $result->{apEnvMonVoltageState}));
        }
        
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{apEnvMonVoltageStatusValue});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s' is '%s' V", $result->{apEnvMonVoltageStatusDescr}, $result->{apEnvMonVoltageStatusValue}));
        }
        $self->{output}->perfdata_add(
            label => 'voltage', unit => 'V',
            nlabel => 'hardware.voltage.volt',
            instances => $result->{apEnvMonVoltageStatusDescr},
            value => $result->{apEnvMonVoltageStatusValue},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
