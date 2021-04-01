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

package network::hp::procurve::snmp::mode::components::fan;

use strict;
use warnings;

my %map_fan_status = (
    0 => 'failed',
    1 => 'removed',
    2 => 'off',
    3 => 'underspeed',
    4 => 'overspeed',
    5 => 'ok',
    6 => 'maxstate',
);

my $mapping = {
    hpicfFanState => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.54.2.1.1.4', map => \%map_fan_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{hpicfFanState}->{oid} };
}

sub check {
    my ($self) = @_;

    
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{hpicfFanState}->{oid}}})) {
        next if ($oid !~ /^$mapping->{hpicfFanState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{hpicfFanState}->{oid}}, instance => $instance);
        
        next if ($self->check_filter(section => 'fan', instance => $instance));
        next if ($result->{hpicfFanState} =~ /removed/i && 
                 $self->absent_problem(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fan '%s' state is %s [instance: %s].",
                                    $instance, $result->{hpicfFanState}, $instance
                                    ));
        my $exit = $self->get_severity(section => 'fan', value => $result->{hpicfFanState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("fan '%s' state is %s", 
                                                             $instance, $result->{hpicfFanState}));
        }
    }
}

1;
