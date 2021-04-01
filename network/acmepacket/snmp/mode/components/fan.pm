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

package network::acmepacket::snmp::mode::components::fan;

use strict;
use warnings;
use network::acmepacket::snmp::mode::components::resources qw($map_status);

my $mapping = {
    apEnvMonFanStatusDescr  => { oid => '.1.3.6.1.4.1.9148.3.3.1.4.1.1.3' },
    apEnvMonFanStatusValue  => { oid => '.1.3.6.1.4.1.9148.3.3.1.4.1.1.4' },
    apEnvMonFanState        => { oid => '.1.3.6.1.4.1.9148.3.3.1.4.1.1.5', map => $map_status },
};
my $oid_apEnvMonFanStatusEntry = '.1.3.6.1.4.1.9148.3.3.1.4.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_apEnvMonFanStatusEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_apEnvMonFanStatusEntry}})) {
        next if ($oid !~ /^$mapping->{apEnvMonFanState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_apEnvMonFanStatusEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'fan', instance => $instance));
        next if ($result->{apEnvMonFanState} =~ /notPresent/i &&
                 $self->absent_problem(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is '%s' [instance = %s, speed = %s]",
                                                        $result->{apEnvMonFanStatusDescr}, $result->{apEnvMonFanState}, $instance, defined($result->{apEnvMonFanStatusValue}) ? $result->{apEnvMonFanStatusValue} : 'unknown'));
        $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{apEnvMonFanState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' status is '%s'", $result->{apEnvMonFanStatusDescr}, $result->{apEnvMonFanState}));
        }
        
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{apEnvMonFanStatusValue});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' is '%s' %%", $result->{apEnvMonFanStatusDescr}, $result->{apEnvMonFanStatusValue}));
        }
        $self->{output}->perfdata_add(
            label => 'fan', unit => '%',
            nlabel => 'hardware.fan.speed.percentage',
            instances => $result->{apEnvMonFanStatusDescr},
            value => $result->{apEnvMonFanStatusValue},
            warning => $warn,
            critical => $crit, min => 0, max => 100
        );
    }
}

1;
