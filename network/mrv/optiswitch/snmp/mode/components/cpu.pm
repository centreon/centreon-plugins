#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::mrv::optiswitch::snmp::mode::components::cpu;

use strict;
use warnings;

my %map_cpu_status = (
    1 => 'none',
    2 => 'active',
    3 => 'notActive',
);

my $mapping = {
    nbsDevCPUOperStatus => { oid => '.1.3.6.1.4.1.629.1.50.11.1.10.2.1.5', map => \%map_cpu_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{nbsDevCPUOperStatus}->{oid} };
}

sub check {
    my ($self) = @_;
 
    $self->{output}->output_add(long_msg => "Checking cpu");
    $self->{components}->{cpu} = {name => 'cpu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cpu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{nbsDevCPUOperStatus}->{oid}}})) {
        next if ($oid !~ /^$mapping->{nbsDevCPUOperStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{nbsDevCPUOperStatus}->{oid}}, instance => $instance);
        
        next if ($self->check_filter(section => 'cpu', instance => $instance));
        $self->{components}->{cpu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("cpu '%s' state is %s [instance: %s].",
                                    $instance, $result->{nbsDevCPUOperStatus}, $instance
                                    ));
        my $exit = $self->get_severity(section => 'cpu', value => $result->{nbsDevCPUOperStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("cpu '%s' state is %s", 
                                                             $instance, $result->{nbsDevCPUOperStatus}));
        }
    }
}

1;
