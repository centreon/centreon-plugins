#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::stormshield::snmp::mode::components::disk;

use strict;
use warnings;

my $mapping = {
    name       => { oid => '.1.3.6.1.4.1.11256.1.10.5.1.2' }, # snsDiskEntryDiskName
    isRaid     => { oid => '.1.3.6.1.4.1.11256.1.10.5.1.4' }, # snsDiskEntryIsRaid
    raidStatus => { oid => '.1.3.6.1.4.1.11256.1.10.5.1.5' }  # snsDiskEntryRaidStatus
};
my $oid_diskEntry = '.1.3.6.1.4.1.11256.1.10.5.1'; # snsDiskEntry

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_diskEntry, end => $mapping->{raidStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking disks');
    $self->{components}->{disk} = { name => 'disks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $oid_diskEntry }})) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $oid_diskEntry }, instance => $instance);
        
        next if ($self->check_filter(section => 'disk', instance => $instance));

        $self->{components}->{disk}->{total}++;
        if ($result->{isRaid} == 0) {
            $self->{output}->output_add(
                long_msg => sprintf(
                    "disk '%s' is not member of a raid [instance: %s]",
                    $result->{name},
                    $instance
                )
            );
            next;
        }

        $self->{output}->output_add(
            long_msg => sprintf(
                "disk '%s' raid status is '%s' [instance: %s]",
                $result->{name},
                $result->{raidStatus},
                $instance
            )
        );

        my $exit = $self->get_severity(section => 'raid', value => $result->{raidStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Disk '%s' raid status is '%s'", $result->{name}, $result->{raidStatus}
                )
            );
        }
    }
}

1;
