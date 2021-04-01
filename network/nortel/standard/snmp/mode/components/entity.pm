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

package network::nortel::standard::snmp::mode::components::entity;

use strict;
use warnings;
use network::nortel::standard::snmp::mode::components::resources qw($map_comp_status);

my $mapping = {
    s5ChasComDescr      => { oid => '.1.3.6.1.4.1.45.1.6.3.3.1.1.5' },
    s5ChasComOperState  => { oid => '.1.3.6.1.4.1.45.1.6.3.3.1.1.10', map => $map_comp_status },
};
my $oid_s5ChasComEntry = '.1.3.6.1.4.1.45.1.6.3.3.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_s5ChasComEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking entities");
    $self->{components}->{entity} = {name => 'entities', total => 0, skip => 0};
    return if ($self->check_filter(section => 'entity'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_s5ChasComEntry}})) {
        next if ($oid !~ /^$mapping->{s5ChasComOperState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_s5ChasComEntry}, instance => $instance);

        next if ($self->check_filter(section => 'entity', instance => $instance));
        $self->{components}->{entity}->{total}++;

        my $name = defined($result->{s5ChasComDescr}) && $result->{s5ChasComDescr} ne '' ?
            $result->{s5ChasComDescr} : $instance;
        $self->{output}->output_add(long_msg => sprintf("entity '%s' status is '%s' [instance: %s].",
                                    $name, $result->{s5ChasComOperState},
                                    $instance
                                    ));
        my $exit = $self->get_severity(section => 'entity', instance => $instance, value => $result->{s5ChasComOperState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Entity '%s' status is '%s'",
                                                             $name, $result->{s5ChasComOperState}));
        }
    }
}

1;