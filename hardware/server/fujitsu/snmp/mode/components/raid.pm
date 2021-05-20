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

package hardware::server::fujitsu::snmp::mode::components::raid;

use strict;
use warnings;

my $map_raid_status = {
    1 => 'unknown', 2 => 'online',
    3 => 'degraded', 4 => 'offline',
    5 => 'rebuilding', 6 => 'verifying',
    7 => 'initializing', 8 => 'morphing',
    9 => 'partialDegraded'
};

my $mapping = {
    status => { oid => '.1.3.6.1.4.1.231.2.49.1.6.2.1.10', map => $map_raid_status }, # svrLogicalDriveStatus
    name   => { oid => '.1.3.6.1.4.1.231.2.49.1.6.2.1.11' } # svrLogicalDriveName
};
my $oid_ldrive_table = '.1.3.6.1.4.1.231.2.49.1.6.2'; # svrLogicalDriveTable

sub load {
    my ($self) = @_;

    push @{$self->{request}}, {
        oid => $oid_ldrive_table,
        start => $mapping->{status}->{oid},
        end => $mapping->{name}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking raids');
    $self->{components}->{raid} = { name => 'raids', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'raid'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $oid_ldrive_table }})) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(\d+)\.(\d+)$/);
        my $instance = $1 . '.' . $2;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $oid_ldrive_table }, instance => $instance);

        next if ($self->check_filter(section => 'disk', instance => $instance));
        $self->{components}->{disk}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "raid '%s' status is '%s' [instance: %s]",
                $result->{name}, $result->{status}, $instance
            )
        );

        my $exit = $self->get_severity(section => 'raid', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Raid '%s' status is '%s'", $result->{name}, $result->{status})
            );
        }
    }
}

1;
