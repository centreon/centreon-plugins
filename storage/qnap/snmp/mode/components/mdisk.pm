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

package storage::qnap::snmp::mode::components::mdisk;

use strict;
use warnings;

my $map_smartinfo = {
    2 => 'abnormal',
    1 => 'warning',
    0 => 'good',
    -1 => 'error'
};

my $mapping = {
    ex => {
        description => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.6.2.1.2' }, # msatadiskID
        status      => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.6.2.1.4' }, # msatadiskSummary
        smartinfo   => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.6.2.1.5', map => $map_smartinfo }, # msatadiskSmartInfo
        temperature => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.6.2.1.6' } # msatadiskTemperature
    }
};

sub load {}

sub check_mdisk_ex {
    my ($self) = @_;

    my $snmp_result = $self->{snmp}->get_table(
        oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.6.2', # msataDiskTable
        start => $mapping->{ex}->{description}->{oid},
        end => $mapping->{ex}->{temperature}->{oid}
    );
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{ex}->{description}->{oid}\.(\d+)$/);
        my $instance = $1;

        my $result = $self->{snmp}->map_instance(mapping => $mapping->{ex}, results => $snmp_result, instance => $instance);

        next if ($self->check_filter(section => 'mdisk', instance => $instance));

        $self->{components}->{mdisk}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "mDisk '%s' status is %s [instance: %s, temperature: %s, smart status: %s]",
                $result->{description},
                $result->{status},
                $instance,
                $result->{temperature}, 
                $result->{smartinfo}
            )
        );
        my $exit = $self->get_severity(label => 'disk', section => 'mdisk', instance => $instance, value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "mDisk '%s' status is %s.", $result->{description}, $result->{status}
                )
            );
        }

        $exit = $self->get_severity(section => 'smartdisk', value => $result->{smartinfo});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "mDisk '%s' smart status is %s.", $result->{description}, $result->{smartinfo}
                )
            );
        }

        next if ($result->{temperature} !~ /([0-9]+)/);

        my $disk_temp = $1;
        my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'mdisk', instance => $instance, value => $disk_temp);
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "mDisk '%s' temperature is %s degree centigrade", $result->{description}, $disk_temp
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.mdisk.temperature.celsius',
            unit => 'C',
            instances => $instance,
            value => $disk_temp
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking mdisks');
    $self->{components}->{mdisk} = { name => 'mdisks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'mdisk'));

    if ($self->{is_es} == 0) {
        check_mdisk_ex($self);
    }
}

1;
