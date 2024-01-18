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

package storage::synology::snmp::mode::components::disk;

use strict;
use warnings;

my $map_disk_status = {
    1 => 'Normal',
    2 => 'Initialized',
    3 => 'NotInitialized',
    4 => 'SystemPartitionFailed',
    5 => 'Crashed'
};
my $map_disk_health = {
    1 => 'normal',
    2 => 'warning',
    3 => 'critical',
    4 => 'failing'
};

my $mapping = {
    status       => { oid => '.1.3.6.1.4.1.6574.2.1.1.5', map => $map_disk_status }, # synoDiskdiskStatus
    badSectors   => { oid => '.1.3.6.1.4.1.6574.2.1.1.9' }, # diskBadSector
    healthStatus => { oid => '.1.3.6.1.4.1.6574.2.1.1.13', map => $map_disk_health } # diskHealthStatus
};
my $oid_diskName = '.1.3.6.1.4.1.6574.2.1.1.2'; # synoDiskdiskName

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_diskName };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disk");
    $self->{components}->{disk} = { name => 'disk', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));

    my $instances = [];
    foreach (keys %{$self->{results}->{$oid_diskName}}) {
        push @$instances, $1 if (/^$oid_diskName\.(.*)$/);
    }

    return if (scalar(@$instances) <= 0);

    $self->{snmp}->load(
        oids => [map($_->{oid}, values(%$mapping))],
        instances => $instances
    );
    my $results = $self->{snmp}->get_leef();

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$results)) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        my $name = $self->{results}->{$oid_diskName}->{$oid_diskName . '.' . $instance};
        next if ($self->check_filter(section => 'disk', instance => $instance));
        $self->{components}->{disk}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "disk '%s' status is %s [instance: %s%s%s]",
                $name, $result->{status}, $instance,
                defined($result->{badSectors}) ? ', bad sectors: ' . $result->{badSectors} : '',
                defined($result->{healthStatus}) ? ', health: ' . $result->{healthStatus} : ''
            )
        );
        my $exit = $self->get_severity(section => 'disk', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Disk '%s' status is %s", $name, $result->{status})
            );
        }

        if (defined($result->{healthStatus})) {
            $exit = $self->get_severity(section => 'disk', value => $result->{healthStatus});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Disk '%s' health is %s", $name, $result->{healthStatus})
                );
            }
        }

        next if (!defined($result->{badSectors}));

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'disk.badsectors', instance => $instance, value => $result->{badSectors});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf("Disk '%s' has %s bad sector(s)", $name, $result->{badSectors})
            );
        }

        $self->{output}->perfdata_add(
            nlabel => 'hardware.disk.bad_sectors.count',
            instances => $name,
            value => $result->{badSectors},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

1;
