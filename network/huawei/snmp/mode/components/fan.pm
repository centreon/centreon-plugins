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

package network::huawei::snmp::mode::components::fan;

use strict;
use warnings;

my $map_present = { 1 => 'present', 2 => 'absent' };
my $map_state = { 1 => 'normal', 2 => 'abnormal' };

my $mapping = {
    hwEntityFanSpeed    => { oid => '.1.3.6.1.4.1.2011.5.25.31.1.1.10.1.5' },
    hwEntityFanPresent  => { oid => '.1.3.6.1.4.1.2011.5.25.31.1.1.10.1.6', map => $map_present },
    hwEntityFanState    => { oid => '.1.3.6.1.4.1.2011.5.25.31.1.1.10.1.7', map => $map_state },
};
my $oid_hwFanStatusEntry = '.1.3.6.1.4.1.2011.5.25.31.1.1.10';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hwFanStatusEntry, start => $mapping->{hwEntityFanSpeed}->{oid}, end => $mapping->{hwEntityFanState}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking fans");
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_hwFanStatusEntry}})) {
        next if ($oid !~ /^$mapping->{hwEntityFanState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hwFanStatusEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'fan', instance => $instance));
        next if ($result->{hwEntityFanPresent} =~ /absent/i &&
                 $self->absent_problem(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg =>
            sprintf("fan '%s' state is '%s' [instance = %s, speed = %s]",
                $instance, $result->{hwEntityFanState}, $instance,
                defined($result->{hwEntityFanSpeed}) ? $result->{hwEntityFanSpeed} : '-')
        );
        
        my $exit = $self->get_severity(section => 'fan', value => $result->{hwEntityFanState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("fan '%s' state is '%s'", $instance, $result->{infoFanState}));
        }        
        
        next if (!defined($result->{hwEntityFanSpeed}) || $result->{hwEntityFanSpeed} !~ /[0-9]/);
        
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{hwEntityFanSpeed});
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("fan '%s' speed is %s %%", $instance, $result->{hwEntityFanSpeed}));
        }
        $self->{output}->perfdata_add(
            label => 'fan', unit => '%',
            nlabel => 'hardware.fan.speed.percentage',
            instances => $instance,
            value => $result->{hwEntityFanSpeed},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

1;
