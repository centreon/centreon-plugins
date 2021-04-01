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

package network::hp::procurve::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (
    1 => 'psNotPresent',
    2 => 'psNotPlugged',
    3 => 'psPowered',
    4 => 'psFailed',
    5 => 'psPermFailure',
    6 => 'psMax',
    7 => 'psAuxFailure',
    8 => 'psNotPowered',
    9 => 'psAuxNotPowered',
);

my $mapping = {
    hpicfPsState => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.55.1.1.1.2', map => \%map_psu_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{hpicfPsState}->{oid} };
}

sub check {
    my ($self) = @_;

    
    $self->{output}->output_add(long_msg => "Checking power supply");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{hpicfPsState}->{oid}}})) {
        next if ($oid !~ /^$mapping->{hpicfPsState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{hpicfPsState}->{oid}}, instance => $instance);
        
        next if ($self->check_filter(section => 'psu', instance => $instance));
        next if ($result->{hpicfPsState} =~ /psNotPresent/i && 
                 $self->absent_problem(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("power supply '%s' state is %s [instance: %s].",
                                    $instance, $result->{hpicfPsState}, $instance
                                    ));
        my $exit = $self->get_severity(section => 'psu', value => $result->{hpicfPsState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("power supply '%s' state is %s", 
                                                             $instance, $result->{hpicfPsState}));
        }
    }
}

1;
