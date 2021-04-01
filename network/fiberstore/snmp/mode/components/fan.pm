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

package network::fiberstore::snmp::mode::components::fan;

use strict;
use warnings;
use centreon::plugins::misc;

my $map_status = {
    1 => 'active', 2 => 'deactive', 3 => 'notInstall', 4 => 'unsupport'
};
my $map_position = {
    1 => 'default', 2 => 'left', 3 => 'right'
};

sub load {
    my ($self) = @_;

    $self->{mapping_fan} = {
        status => { oid => $self->{branch} . '.37.1.1.1.1.4', map => $map_status }, # devMFanStatus
        speed  => { oid => $self->{branch} .  '.37.1.1.1.1.5' } # devMFanSpeed
    };
    $self->{table_fan} = $self->{branch} . '.37.1.1.1';
    
    push @{$self->{request}}, {
        oid => $self->{table_fan},
        start => $self->{mapping_fan}->{status}->{oid},
        end => $self->{mapping_fan}->{speed}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking fans');
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{table_fan} }})) {
        next if ($oid !~ /^$self->{mapping_fan}->{status}->{oid}\.(\d+)\.(\d+)\.(\d+)$/);
        my ($position, $instance) = ($1, $1 . '.' . $2 . '.' . $3);
        my $description = $map_position->{$position} . ':' . $2 . ':' . $3;
        my $result = $self->{snmp}->map_instance(mapping => $self->{mapping_fan}, results => $self->{results}->{ $self->{table_fan} }, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance));

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is '%s' [instance: %s, speed: %s]",
                $description, $result->{status}, $instance, centreon::plugins::misc::trim($result->{speed})
            )
        );

        my $exit = $self->get_severity(section => 'fan', instance => $instance, value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Fan '%s' status is %s", $description, $result->{status}
                )
            );
        }

        next if ($result->{speed} !~ /([0-9]+)\s*%/i);

        my $fan_speed_value = $1;
        my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'fan.speed', instance => $instance, value => $fan_speed_value);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Fan '%s' speed is %s %%", $description, $fan_speed_value
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.fan.speed.percentage',
            unit => '%',
            instances => $description,
            value => $fan_speed_value,
            min => 0,
            max => 100
        );
    }
}

1;
