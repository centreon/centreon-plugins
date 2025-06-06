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

package storage::qnap::snmp::mode::components::raid;

use strict;
use warnings;

sub load {}

sub check_raid_qts {
    my ($self) = @_;

    my $mapping = {
        name   => { oid => '.1.3.6.1.4.1.55062.1.10.5.1.3' },# raidName
        status => { oid => '.1.3.6.1.4.1.55062.1.10.5.1.4' }# raidStatus
    };
    my $snmp_result = $self->{snmp}->get_table(
        oid   => '.1.3.6.1.4.1.55062.1.10.5',# raidTable
        start => $mapping->{name}->{oid},
        end   => $mapping->{status}->{oid}
    );
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(\d+)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if ($self->check_filter(section => 'raid', instance => $instance));

        $self->{components}->{raid}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "raid '%s' status is %s [instance: %s]",
                $result->{name}, $result->{status}, $instance
            )
        );
        my $exit = $self->get_severity(section => 'raid', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "Raid '%s' status is %s.", $result->{name}, $result->{status}
                )
            );
        }
    }
}

sub check_raid_quts {
    my ($self) = @_;

    my $mapping = {
        name   => { oid => '.1.3.6.1.4.1.55062.2.10.5.1.3' },# raidName
        status => { oid => '.1.3.6.1.4.1.55062.2.10.5.1.4' }# raidStatus
    };
    my $snmp_result = $self->{snmp}->get_table(
        oid   => '.1.3.6.1.4.1.55062.2.10.5',# raidTable
        start => $mapping->{name}->{oid},
        end   => $mapping->{status}->{oid}
    );
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(\d+)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if ($self->check_filter(section => 'raid', instance => $instance));

        $self->{components}->{raid}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "raid '%s' status is %s [instance: %s]",
                $result->{name}, $result->{status}, $instance
            )
        );
        my $exit = $self->get_severity(section => 'raid', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "Raid '%s' status is %s.", $result->{name}, $result->{status}
                )
            );
        }
    }
}

sub check_raid_ex {
    my ($self) = @_;

    my $snmp_result = $self->{snmp}->get_table(
        oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.2.1.2.1.5'# raidStatus
    );
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;

        next if ($self->check_filter(section => 'raid', instance => $instance));

        my $status = $snmp_result->{$oid};
        $self->{components}->{raid}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "raid '%s' status is %s [instance: %s]",
                $instance, $status, $instance
            )
        );
        my $exit = $self->get_severity(section => 'raid', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "Raid '%s' status is %s.", $instance, $status
                )
            );
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking raids");
    $self->{components}->{raid} = { name => 'raids', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'raid'));

    if ($self->{is_qts} == 1) {
        check_raid_qts($self);
    } elsif ($self->{is_quts} == 1) {
        check_raid_quts($self);
    } elsif ($self->{is_es} == 0) {
        check_raid_ex($self);
    }
}

1;
