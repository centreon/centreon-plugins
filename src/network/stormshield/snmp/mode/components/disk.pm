#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

# Single-node OIDs — structure: oid.<disk_id>
my $mapping_single = {
    name        => { oid => '.1.3.6.1.4.1.11256.1.10.5.1.2' }, # snsDiskEntryDiskName
    smartResult => { oid => '.1.3.6.1.4.1.11256.1.10.5.1.3' }, # snsDiskEntrySmartResult
    isRaid      => { oid => '.1.3.6.1.4.1.11256.1.10.5.1.4' }, # snsDiskEntryIsRaid
    raidStatus  => { oid => '.1.3.6.1.4.1.11256.1.10.5.1.5' }, # snsDiskEntryRaidStatus
    position    => { oid => '.1.3.6.1.4.1.11256.1.10.5.1.6' }  # snsDiskEntryPosition
};
my $oid_diskEntry_single = '.1.3.6.1.4.1.11256.1.10.5.1';      # snsDiskEntry

# HA OIDs — structure: oid.<node_id>.<disk_id>
my $oid_disk_name_ha        = '.1.3.6.1.4.1.11256.1.11.11.1.2'; # snsNodeDiskName
my $oid_disk_smartResult_ha = '.1.3.6.1.4.1.11256.1.11.11.1.3'; # snsNodeDiskSmartResult
my $oid_disk_isRaid_ha      = '.1.3.6.1.4.1.11256.1.11.11.1.4'; # snsNodeDiskIsRaid
my $oid_disk_raidStatus_ha  = '.1.3.6.1.4.1.11256.1.11.11.1.5'; # snsNodeDiskRaidStatus
my $oid_disk_position_ha    = '.1.3.6.1.4.1.11256.1.11.11.1.6'; # snsNodeDiskPosition
my $oid_diskEntry_ha        = '.1.3.6.1.4.1.11256.1.11.11.1';   # snsNodeDiskEntry

sub load {
    my ($self) = @_;

    if ($self->{is_ha}) {
        push @{$self->{request}}, { oid => $oid_diskEntry_ha };
    } else {
        push @{$self->{request}}, { oid => $oid_diskEntry_single, end => $mapping_single->{position}->{oid} };
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking disks');
    $self->{components}->{disk} = { name => 'disks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));

    my $nodes   = $self->{is_ha} ? $self->{ha_nodes} : ['0'];
    my $serials = $self->{ha_serials};

    foreach my $node_id (@$nodes) {
        my $label_prefix = $self->{is_ha} ? $serials->{$node_id} . '_' : '';
        my %disks_data   = ();

        if ($self->{is_ha}) {
            foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_diskEntry_ha}})) {
                if ($oid =~ /^$oid_disk_name_ha\.$node_id\.(\d+)$/) {
                    $disks_data{$1}{name} = $self->{results}->{$oid_diskEntry_ha}->{$oid};
                } elsif ($oid =~ /^$oid_disk_smartResult_ha\.$node_id\.(\d+)$/) {
                    $disks_data{$1}{smartResult} = $self->{results}->{$oid_diskEntry_ha}->{$oid};
                } elsif ($oid =~ /^$oid_disk_isRaid_ha\.$node_id\.(\d+)$/) {
                    $disks_data{$1}{isRaid} = $self->{results}->{$oid_diskEntry_ha}->{$oid};
                } elsif ($oid =~ /^$oid_disk_raidStatus_ha\.$node_id\.(\d+)$/) {
                    $disks_data{$1}{raidStatus} = $self->{results}->{$oid_diskEntry_ha}->{$oid};
                } elsif ($oid =~ /^$oid_disk_position_ha\.$node_id\.(\d+)$/) {
                    $disks_data{$1}{position} = $self->{results}->{$oid_diskEntry_ha}->{$oid};
                }
            }
        } else {
            foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_diskEntry_single}})) {
                next if ($oid !~ /^$mapping_single->{name}->{oid}\.(\d+)$/);
                my $disk_id = $1;
                my $result  = $self->{snmp}->map_instance(
                    mapping  => $mapping_single,
                    results  => $self->{results}->{$oid_diskEntry_single},
                    instance => $disk_id
                );
                $disks_data{$disk_id} = $result;
            }
        }

        foreach my $disk_id (sort { $a <=> $b } keys %disks_data) {
            my $disk     = $disks_data{$disk_id};
            my $instance = $label_prefix . 'disk' . $disk_id;

            next if ($self->check_filter(section => 'disk', instance => $instance));
            $self->{components}->{disk}->{total}++;

            my $smart  = $disk->{smartResult} // 'N/A';
            my $name   = $label_prefix . $disk->{name}        // $instance;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "disk '%s' smart result is '%s' [isRaid: %s, raidStatus: %s, position: %s]",
                    $name,
                    $smart,
                    (defined $disk->{isRaid}     && $disk->{isRaid} == 1)    ? 'true' : 'false',
                    (defined $disk->{raidStatus} && $disk->{raidStatus} ne '') ? $disk->{raidStatus} : '/',
                    $disk->{position} // 'N/A'
                )
            );

            my $exit = $self->get_severity(section => 'disk', value => $smart);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity  => $exit,
                    short_msg => sprintf("Disk '%s' smart result is '%s'", $name, $smart)
                );
            }

            if (defined $disk->{isRaid} && $disk->{isRaid} == 1
                && defined $disk->{raidStatus} && $disk->{raidStatus} ne ''
                && $disk->{raidStatus} ne 'optimal')
            {
                $self->{output}->output_add(
                    severity  => 'WARNING',
                    short_msg => sprintf(
                        "Disk '%s' RAID status is '%s'", $name, $disk->{raidStatus}
                    )
                );
            }
        }
    }
}

1;