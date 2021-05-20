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

package hardware::server::fujitsu::snmp::mode::components::disk;

use strict;
use warnings;

my $map_drive_status = {
    1 => 'unknown', 2 => 'noDisk',
    3 => 'online', 4 => 'ready',
    5 => 'failed', 6 => 'rebuilding',
    7 => 'hotspareGlobal', 8 => 'hotspareDedicated',
    9 => 'offline', 10 => 'unconfiguredFailed',
    11 => 'formatting', 12 => 'dead'
};

my $mapping = {
    status => { oid => '.1.3.6.1.4.1.231.2.49.1.5.2.1.15', map => $map_drive_status } # svrPhysicalDeviceStatus
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $mapping->{status}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking disks');
    $self->{components}->{disk} = { name => 'disks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping->{status}->{oid} }})) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
        my $instance = $1 . '.' . $2 . '.' . $3 . '.' . $4;
        my $name = $1 . ':' . $2 . ':' . $3 . ':' . $4;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{status}->{oid} }, instance => $instance);

        next if ($self->check_filter(section => 'disk', instance => $instance));
        $self->{components}->{disk}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "disk '%s' status is '%s' [instance: %s]",
                $name, $result->{status}, $instance
            )
        );

        my $exit = $self->get_severity(section => 'disk', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Disk '%s' status is '%s'", $name, $result->{status})
            );
        }
    }
}

1;
