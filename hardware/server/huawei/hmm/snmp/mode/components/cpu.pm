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

package hardware::server::huawei::hmm::snmp::mode::components::cpu;

use strict;
use warnings;

my %map_status = (
    1 => 'normal',
    2 => 'minor',
    3 => 'major',
    4 => 'critical',
);

my %map_installation_status = (
    0 => 'absence',
    1 => 'presence',
    2 => 'poweroff',
);

my $mapping = {
    bladeCPUMark            => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2006.1.2' },
    bladeCPUPresent         => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2006.1.4', map => \%map_installation_status },
    bladeCPUHealth          => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2006.1.5', map => \%map_status },
    bladeCPUTemperature     => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2006.1.7' },
};
my $oid_bladeCPUTable = '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2006.1';

sub load {
    my ($self) = @_;

    $oid_bladeCPUTable =~ s/#/$self->{blade_id}/;
    push @{$self->{request}}, { oid => $oid_bladeCPUTable };
}

sub check {
    my ($self) = @_;

    foreach my $entry (keys $mapping) {
        $mapping->{$entry}->{oid} =~ s/#/$self->{blade_id}/;
    }

    $self->{output}->output_add(long_msg => "Checking CPUs");
    $self->{components}->{cpu} = {name => 'cpus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cpu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_bladeCPUTable}})) {
        next if ($oid !~ /^$mapping->{bladeCPUHealth}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_bladeCPUTable}, instance => $instance);

        next if ($self->check_filter(section => 'cpu', instance => $instance));
        next if ($result->{bladeCPUPresent} !~ /presence/);
        $self->{components}->{cpu}->{total}++;

        if (defined($result->{bladeCPUTemperature}) && $result->{bladeCPUTemperature} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'cpu', instance => $instance, value => $result->{bladeCPUTemperature});
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Cpu '%s' temperature is %s celsius degrees", $result->{bladeCPUMark}, $result->{bladeCPUTemperature}));
            }
            $self->{output}->perfdata_add(
                label => 'temperature', unit => 'C',
                nlabel => 'hardware.cpu.temperature.celsius',
                instances => $result->{bladeCPUMark},
                value => $result->{bladeCPUTemperature},
                warning => $warn,
                critical => $crit, min => 0
            );
        }
        
        $self->{output}->output_add(long_msg => sprintf("Cpu '%s' status is '%s' [instance = %s]",
                                    $result->{bladeCPUMark}, $result->{bladeCPUHealth}, $instance, 
                                    ));
   
        my $exit = $self->get_severity(label => 'default', section => 'Cpu', value => $result->{bladeCPUHealth});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Cpu '%s' status is '%s'", $result->{bladeCPUMark}, $result->{bladeCPUHealth}));
        }
    }
}

1;
