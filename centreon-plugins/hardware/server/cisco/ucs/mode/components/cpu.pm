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

package hardware::server::cisco::ucs::mode::components::cpu;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw(%mapping_presence %mapping_operability);

# In MIB 'CISCO-UNIFIED-COMPUTING-PROCESSOR-MIB'
my $mapping1 = {
    cucsProcessorUnitPresence => { oid => '.1.3.6.1.4.1.9.9.719.1.41.9.1.13', map => \%mapping_presence },
};
my $mapping2 = {
    cucsProcessorUnitOperState => { oid => '.1.3.6.1.4.1.9.9.719.1.41.9.1.9', map => \%mapping_operability },
};
my $oid_cucsProcessorUnitDn = '.1.3.6.1.4.1.9.9.719.1.41.9.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping1->{cucsProcessorUnitPresence}->{oid} },
        { oid => $mapping2->{cucsProcessorUnitOperState}->{oid} }, { oid => $oid_cucsProcessorUnitDn };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cpus");
    $self->{components}->{cpu} = {name => 'cpus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cpu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cucsProcessorUnitDn}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $cpu_dn = $self->{results}->{$oid_cucsProcessorUnitDn}->{$oid};
        my $result = $self->{snmp}->map_instance(mapping => $mapping1, results => $self->{results}->{$mapping1->{cucsProcessorUnitPresence}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{cucsProcessorUnitOperState}->{oid}}, instance => $instance);
        
        next if ($self->absent_problem(section => 'cpu', instance => $cpu_dn));
        next if ($self->check_filter(section => 'cpu', instance => $cpu_dn));

        $self->{output}->output_add(
            long_msg => sprintf(
                "cpu '%s' state is '%s' [presence: %s].",
                $cpu_dn, $result2->{cucsProcessorUnitOperState},
                $result->{cucsProcessorUnitPresence}
            )
        );

        my $exit = $self->get_severity(section => 'cpu.presence', label => 'default.presence', value => $result->{cucsProcessorUnitPresence});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "cpu '%s' presence is: '%s'",
                    $cpu_dn, $result->{cucsProcessorUnitPresence}
                )
            );
            next;
        }

        $self->{components}->{cpu}->{total}++;

        $exit = $self->get_severity(section => 'cpu.operability', label => 'default.operability', value => $result2->{cucsProcessorUnitOperState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "cpu '%s' state is '%s'",
                    $cpu_dn, $result2->{cucsProcessorUnitOperState}
                )
            );
        }
    }
}

1;
