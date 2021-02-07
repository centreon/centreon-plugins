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

package hardware::server::cisco::ucs::mode::components::memory;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw(%mapping_presence %mapping_operability);

# In MIB 'CISCO-UNIFIED-COMPUTING-MEMORY-MIB'
my $mapping1 = {
    cucsMemoryUnitPresence => { oid => '.1.3.6.1.4.1.9.9.719.1.30.11.1.17', map => \%mapping_presence },
};
my $mapping2 = {
    cucsMemoryUnitOperState => { oid => '.1.3.6.1.4.1.9.9.719.1.30.11.1.13', map => \%mapping_operability },
};
my $oid_cucsMemoryUnitDn = '.1.3.6.1.4.1.9.9.719.1.30.11.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping1->{cucsMemoryUnitPresence}->{oid} },
        { oid => $mapping2->{cucsMemoryUnitOperState}->{oid} }, { oid => $oid_cucsMemoryUnitDn };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking memories");
    $self->{components}->{memory} = {name => 'memories', total => 0, skip => 0};
    return if ($self->check_filter(section => 'memory'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cucsMemoryUnitDn}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $memory_dn = $self->{results}->{$oid_cucsMemoryUnitDn}->{$oid};
        $memory_dn =~ s/\n$//ms;
        my $result = $self->{snmp}->map_instance(mapping => $mapping1, results => $self->{results}->{$mapping1->{cucsMemoryUnitPresence}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{cucsMemoryUnitOperState}->{oid}}, instance => $instance);
        
        next if ($self->absent_problem(section => 'memory', instance => $memory_dn));
        next if ($self->check_filter(section => 'memory', instance => $memory_dn));

        $self->{output}->output_add(
            long_msg => sprintf(
                "memory '%s' state is '%s' [presence: %s].",
                $memory_dn, $result2->{cucsMemoryUnitOperState},
                $result->{cucsMemoryUnitPresence}
            )
        );

        my $exit = $self->get_severity(section => 'memory.presence', label => 'default.presence', value => $result->{cucsMemoryUnitPresence});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "memory '%s' presence is: '%s'",
                    $memory_dn, $result->{cucsMemoryUnitPresence}
                )
            );
            next;
        }
        
        $self->{components}->{memory}->{total}++;

        $exit = $self->get_severity(section => 'memory.operability', label => 'default.operability', value => $result2->{cucsMemoryUnitOperState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "memory '%s' state is '%s'",
                    $memory_dn, $result2->{cucsMemoryUnitOperState}
                )
            );
        }
    }
}

1;
