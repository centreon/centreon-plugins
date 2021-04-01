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

package storage::qnap::snmp::mode::components::disk;

use strict;
use warnings;

my $map_status_disk = {
    0 => 'ready',
    '-5' => 'noDisk',
    '-6' => 'invalid',
    '-9' => 'rwError',
    '-4' => 'unknown'
};
my $map_smartinfo = {
    2 => 'abnormal',
    1 => 'warning',
    0 => 'good',
    -1 => 'error'
};

# In MIB 'NAS.mib'
my $mapping = {
    description => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.2' }, # hdDescr
    temperature => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.3' }, # hdTemperature
    status      => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.4', map => $map_status_disk }, # HdStatus
    smartinfo   => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.7' }  # HdSmartInfo
};
my $mapping2 = {
    description => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.2' }, # diskID
    status      => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.5', map => $map_smartinfo }, # diskSmartInfo
    temperature => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.6' } # diskTemperture
};
my $oid_HdEntry = '.1.3.6.1.4.1.24681.1.2.11.1';
my $oid_diskTableEntry = '.1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_HdEntry, start => $mapping->{description}->{oid} };
    push @{$self->{request}}, {
        oid => $oid_diskTableEntry,
        start => $mapping2->{description}->{oid},
        end => $mapping2->{temperature}->{oid}
    };
}

sub check_disk {
    my ($self, %options) = @_;

    return if (defined($self->{disk_checked}));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $options{entry} }})) {
        next if ($oid !~ /^$options{mapping}->{description}->{oid}\.(\d+)$/);
        my $instance = $1;
        $self->{disk_checked} = 1;

        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{ $options{entry} }, instance => $instance);

        next if ($self->check_filter(section => 'disk', instance => $instance));
        next if ($result->{status} eq 'noDisk' && 
                 $self->absent_problem(section => 'disk', instance => $instance));
        
        $self->{components}->{disk}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "Disk '%s' [instance: %s, temperature: %s, smart status: %s] status is %s.",
                $result->{description},
                $instance,
                $result->{temperature}, 
                defined($result->{smartinfo}) ? $result->{smartinfo} : '-',
                $result->{status}
            )
        );
        my $exit = $self->get_severity(section => 'disk', instance => $instance, value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Disk '%s' status is %s.", $result->{description}, $result->{status}
                )
            );
        }

        if (defined($result->{smartinfo})) {
            $exit = $self->get_severity(section => 'smartdisk', value => $result->{smartinfo});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Disk '%s' smart status is %s.", $result->{description}, $result->{smartinfo}
                    )
                );
            }
        }

        next if ($result->{temperature} !~ /([0-9]+)/);

        my $disk_temp = $1;
        my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'disk', instance => $instance, value => $disk_temp);
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Disk '%s' temperature is %s degree centigrade", $result->{description}, $disk_temp
                )
            );
        }
        $self->{output}->perfdata_add(
            label => 'temp_disk',
            nlabel => 'hardware.disk.temperature.celsius',
            unit => 'C',
            instances => $instance,
            value => $disk_temp
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking disks');
    $self->{components}->{disk} = { name => 'disks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));

    check_disk(
        $self,
        mapping => $mapping2,
        entry => $oid_diskTableEntry
    );
    check_disk(
        $self,
        mapping => $mapping,
        entry => $oid_HdEntry
    );
}

1;
