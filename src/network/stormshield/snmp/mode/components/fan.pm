#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::stormshield::snmp::mode::components::fan;

use strict;
use warnings;

# Single-node OIDs — structure: oid.<fan_id>
my $mapping_single = {
    name   => { oid => '.1.3.6.1.4.1.11256.1.10.9.1.2' }, # snsFanName
    status => { oid => '.1.3.6.1.4.1.11256.1.10.9.1.3' }, # snsFanStatus
    rpm    => { oid => '.1.3.6.1.4.1.11256.1.10.9.1.4' }  # snsFanRpm
};
my $oid_fanEntry_single = '.1.3.6.1.4.1.11256.1.10.9.1';  # snsFanEntry

# HA OIDs — structure: oid.<node_id>.<fan_id>
my $oid_fan_name_ha   = '.1.3.6.1.4.1.11256.1.11.13.1.2'; # snsNodeFanName
my $oid_fan_status_ha = '.1.3.6.1.4.1.11256.1.11.13.1.3'; # snsNodeFanStatus
my $oid_fan_rpm_ha    = '.1.3.6.1.4.1.11256.1.11.13.1.4'; # snsNodeFanRpm
my $oid_fanEntry_ha   = '.1.3.6.1.4.1.11256.1.11.13.1';   # snsNodeFanEntry

sub load {
    my ($self) = @_;

    if ($self->{is_ha}) {
        push @{$self->{request}}, { oid => $oid_fanEntry_ha };
    } else {
        push @{$self->{request}}, { oid => $oid_fanEntry_single };
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking fans');
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    my $nodes   = $self->{is_ha} ? $self->{ha_nodes} : ['0'];
    my $serials = $self->{ha_serials};

    foreach my $node_id (@$nodes) {
        my $label_prefix = $self->{is_ha} ? $serials->{$node_id} . '_' : '';
        my %fans_data    = ();

        if ($self->{is_ha}) {
            foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fanEntry_ha}})) {
                if ($oid =~ /^$oid_fan_name_ha\.$node_id\.(\d+)$/) {
                    $fans_data{$1}{name} = $self->{results}->{$oid_fanEntry_ha}->{$oid};
                } elsif ($oid =~ /^$oid_fan_status_ha\.$node_id\.(\d+)$/) {
                    $fans_data{$1}{status} = $self->{results}->{$oid_fanEntry_ha}->{$oid};
                } elsif ($oid =~ /^$oid_fan_rpm_ha\.$node_id\.(\d+)$/) {
                    $fans_data{$1}{rpm} = $self->{results}->{$oid_fanEntry_ha}->{$oid};
                }
            }
        } else {
            foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fanEntry_single}})) {
                next if ($oid !~ /^$mapping_single->{name}->{oid}\.(\d+)$/);
                my $fan_id = $1;
                my $result = $self->{snmp}->map_instance(
                    mapping  => $mapping_single,
                    results  => $self->{results}->{$oid_fanEntry_single},
                    instance => $fan_id
                );
                $fans_data{$fan_id} = $result;
            }
        }

        foreach my $fan_id (sort { $a <=> $b } keys %fans_data) {
            my $fan      = $fans_data{$fan_id};
            my $instance = $label_prefix . $fan->{name};

            next if ($self->check_filter(section => 'fan', instance => $instance));
            $self->{components}->{fan}->{total}++;

            my $status = $fan->{status} // 'unknown';

            $self->{output}->output_add(
                long_msg => sprintf(
                    "fan '%s' status is '%s'",
                    $instance, $status
                )
            );

            if (defined $fan->{rpm}) {
                $self->{output}->perfdata_add(
                    nlabel    => 'hardware.fan.speed.rpm',
                    unit      => 'rpm',
                    instances => $instance,
                    value     => $fan->{rpm},
                    min       => 0
                );
            }

            my $exit = $self->get_severity(section => 'fan', value => $status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity  => $exit,
                    short_msg => sprintf("Fan '%s' status is '%s'", $instance, $status)
                );
            }
        }
    }
}

1;