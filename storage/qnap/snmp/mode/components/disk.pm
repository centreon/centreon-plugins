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

my $mapping = {
    legacy => {
        description => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.2' }, # hdDescr
        temperature => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.3' }, # hdTemperature ("40 C/104 F")
        status      => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.4', map => $map_status_disk }, # HdStatus
        smartinfo   => { oid => '.1.3.6.1.4.1.24681.1.2.11.1.7' }  # HdSmartInfo
    },
    ex => {
        description => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.2' }, # diskID
        status      => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.5', map => $map_smartinfo }, # diskSmartInfo
        temperature => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2.1.6' } # diskTemperture
    },
    es => {
        description => { oid => '.1.3.6.1.4.1.24681.2.2.11.1.2' }, # es-HdDescr
        temperature => { oid => '.1.3.6.1.4.1.24681.2.2.11.1.3' }, # es-HdTemperature ("26 C/78.8 F")
        status      => { oid => '.1.3.6.1.4.1.24681.2.2.11.1.4' }, # es-HdStatus
        smartinfo   => { oid => '.1.3.6.1.4.1.24681.2.2.11.1.7' }  # es-HdSmartInfo
    }
};

sub load {}

sub check_disk_legacy {
    my ($self, %options) = @_;

    return if (defined($self->{disk_checked}));

    my $snmp_result = $self->{snmp}->get_table(
        oid => '.1.3.6.1.4.1.24681.1.2.11', # systemHdTable
        start => $mapping->{description}->{oid}
    ); 

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{legacy}->{description}->{oid}\.(\d+)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping->{legacy}, results => $snmp_result, instance => $instance);

        next if ($self->check_filter(section => 'disk', instance => $instance));
        next if (
            $result->{status} eq 'noDisk' && 
            $self->absent_problem(section => 'disk', instance => $instance)
        );

        $self->{components}->{disk}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "disk '%s' status is %s [instance: %s, temperature: %s, smart status: %s]",
                $result->{description},
                $result->{status},
                $instance,
                $result->{temperature}, 
                defined($result->{smartinfo}) ? $result->{smartinfo} : '-',
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
            nlabel => 'hardware.disk.temperature.celsius',
            unit => 'C',
            instances => $instance,
            value => $disk_temp
        );
    }
}

sub check_disk_ex {
    my ($self, %options) = @_;

    my $snmp_result = $self->{snmp}->get_table(
        oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.5.2', # diskTable
        start => $mapping->{ex}->{description}->{oid},
        end => $mapping->{ex}->{temperature}->{oid}
    );
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{ex}->{description}->{oid}\.(\d+)$/);
        my $instance = $1;
        $self->{disk_checked} = 1;

        my $result = $self->{snmp}->map_instance(mapping => $mapping->{ex}, results => $snmp_result, instance => $instance);

        next if ($self->check_filter(section => 'disk', instance => $instance));

        $self->{components}->{disk}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "disk '%s' status is %s [instance: %s, temperature: %s]",
                $result->{description},
                $result->{status},
                $instance,
                $result->{temperature}
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
            nlabel => 'hardware.disk.temperature.celsius',
            unit => 'C',
            instances => $instance,
            value => $disk_temp
        );
    }
}

sub check_disk_es {
    my ($self, %options) = @_;

    my $snmp_result = $self->{snmp}->get_table(oid => '.1.3.6.1.4.1.24681.2.2.11'); # es-SystemHdTable
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{es}->{description}->{oid}\.(\d+)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping->{es}, results => $snmp_result, instance => $instance);

        next if ($self->check_filter(section => 'disk', instance => $instance));
        
        $self->{components}->{disk}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "disk '%s' status is %s [instance: %s, temperature: %s, smart status: %s]",
                $result->{description},
                $result->{status},
                $instance,
                $result->{temperature}, 
                defined($result->{smartinfo}) ? $result->{smartinfo} : '-',
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

    if ($self->{is_es} == 1) {
        check_disk_es($self);
    } else {
        check_disk_ex($self);
        check_disk_legacy($self);
    }
}

1;
