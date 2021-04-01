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

package storage::synology::snmp::mode::components::raid;

use strict;
use warnings;

my $map_raid_status = {
    1 => 'Normal',
    2 => 'Repairing',
    3 => 'Migrating',
    4 => 'Expanding',
    5 => 'Deleting',
    6 => 'Creating',
    7 => 'RaidSyncing',
    8 => 'RaidParityChecking',
    9 => 'RaidAssembling',
    10 => 'Canceling',
    11 => 'Degrade',
    12 => 'Crashed',
    13 => 'DataScrubbing',
    14 => 'RaidDeploying',
    15 => 'RaidUnDeploying',
    16 => 'RaidMountCache',
    17 => 'RaidUnmountCache',
    18 => 'RaidExpandingUnfinishedSHR',
    19 => 'RaidConvertSHRToPool',
    20 => 'RaidMigrateSHR1ToSHR2',
    21 => 'RaidUnknownStatus'
};

my $mapping = {
    synoRaidraidName    => { oid => '.1.3.6.1.4.1.6574.3.1.1.2' },
    synoRaidraidStatus  => { oid => '.1.3.6.1.4.1.6574.3.1.1.3', map => $map_raid_status }
};
my $oid_synoRaid = '.1.3.6.1.4.1.6574.3.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_synoRaid,
        start => $mapping->{synoRaidraidName}->{oid},
        end => $mapping->{synoRaidraidStatus}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking raid");
    $self->{components}->{raid} = {name => 'raid', total => 0, skip => 0};
    return if ($self->check_filter(section => 'raid'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_synoRaid}})) {
        next if ($oid !~ /^$mapping->{synoRaidraidStatus}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_synoRaid}, instance => $instance);

        next if ($self->check_filter(section => 'raid', instance => $instance));
        $self->{components}->{raid}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "raid '%s' status is %s [instance: %s]",
                $result->{synoRaidraidName}, $result->{synoRaidraidStatus}, $instance
            )
        );

        my $exit = $self->get_severity(section => 'raid', value => $result->{synoRaidraidStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Raid '%s' status is %s", 
                    $result->{synoRaidraidName}, $result->{synoRaidraidStatus}
                )
            );
        }
    }
}

1;
