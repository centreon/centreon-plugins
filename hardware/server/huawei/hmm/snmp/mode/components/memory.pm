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

package hardware::server::huawei::hmm::snmp::mode::components::memory;

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
    bladeMemoryMark            => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2007.1.2' },
    bladeMemoryPresent         => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2007.1.4', map => \%map_installation_status },
    bladeMemoryHealth          => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2007.1.5', map => \%map_status },
};
my $oid_bladeMemoryTable = '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2007.1';

sub load {
    my ($self) = @_;

    $oid_bladeMemoryTable =~ s/#/$self->{blade_id}/;
    push @{$self->{request}}, { oid => $oid_bladeMemoryTable };
}

sub check {
    my ($self) = @_;

    foreach my $entry (keys $mapping) {
        $mapping->{$entry}->{oid} =~ s/#/$self->{blade_id}/;
    }

    $self->{output}->output_add(long_msg => "Checking memory slots");
    $self->{components}->{memory} = {name => 'memory slots', total => 0, skip => 0};
    return if ($self->check_filter(section => 'memory'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_bladeMemoryTable}})) {
        next if ($oid !~ /^$mapping->{bladeMemoryHealth}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_bladeMemoryTable}, instance => $instance);

        next if ($self->check_filter(section => 'memory', instance => $instance));
        next if ($result->{bladeMemoryPresent} !~ /presence/);
        $self->{components}->{memory}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Memory '%s' status is '%s' [instance = %s]",
                                    $result->{bladeMemoryMark}, $result->{bladeMemoryHealth}, $instance, 
                                    ));
   
        my $exit = $self->get_severity(label => 'default', section => 'memory', value => $result->{bladeMemoryHealth});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Memory '%s' status is '%s'", $result->{bladeMemoryMark}, $result->{bladeMemoryHealth}));
        }
    }
}

1;