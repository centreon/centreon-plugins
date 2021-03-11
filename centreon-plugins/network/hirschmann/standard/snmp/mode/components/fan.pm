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

package network::hirschmann::standard::snmp::mode::components::fan;

use strict;
use warnings;

my $map_classic_fan_state = {
    1 => 'ok', 
    2 => 'failed'
};
my $map_hios_fan_state = {
    1 => 'not-available',
    2 => 'available-and-ok',
    3 => 'available-but-failure'
};

my $mapping_classic_fan = {
    fan_state => { oid => '.1.3.6.1.4.1.248.14.1.3.1.3', map => $map_classic_fan_state } # hmFanState
};
my $mapping_hios_fan = {
    fan_state => { oid => '.1.3.6.1.4.1.248.11.13.1.1.2.1.2', map => $map_hios_fan_state } # hm2FanModuleMgmtStatus
};

sub load {
    my ($self) = @_;

    push @{$self->{myrequest}->{hios}}, 
        { oid => $mapping_hios_fan->{fan_state}->{oid} };
    push @{$self->{myrequest}->{classic}}, 
        { oid => $mapping_classic_fan->{fan_state}->{oid} };
}

sub check_fan_classic {
    my ($self) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping_classic_fan->{fan_state}->{oid} }})) {
        next if ($oid !~ /^$mapping_classic_fan->{fan_state}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $mapping_classic_fan,
            results => $self->{results}->{ $mapping_classic_fan->{fan_state}->{oid} },
            instance => $instance
        );

        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is %s [instance: %s].",
                $instance, $result->{fan_state},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'fan', value => $result->{fan_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "fan '%s' status is %s",
                    $instance, $result->{fan_state}
                )
            );
        }
    }
}

sub check_fan_hios {
    my ($self) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping_hios_fan->{fan_state}->{oid} }})) {
        next if ($oid !~ /^$mapping_hios_fan->{fan_state}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $mapping_hios_fan,
            results => $self->{results}->{ $mapping_hios_fan->{fan_state}->{oid} },
            instance => $instance
        );

        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is %s [instance: %s].",
                $instance, $result->{fan_state},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'fan', value => $result->{fan_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "fan '%s' status is %s",
                    $instance, $result->{fan_state}
                )
            );
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    check_fan_classic($self) if ($self->{os_type} eq 'classic');
    check_fan_hios($self) if ($self->{os_type} eq 'hios');
}

1;
