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

package network::stormshield::snmp::mode::components::psu;

use strict;
use warnings;

# Single-node OIDs — structure: oid.<psu_id>
my $mapping_single = {
    powered => { oid => '.1.3.6.1.4.1.11256.1.10.6.1.2' }, # snsPowerSupplyPowered
    status  => { oid => '.1.3.6.1.4.1.11256.1.10.6.1.3' }  # snsPowerSupplyStatus
};
my $oid_psuEntry_single = '.1.3.6.1.4.1.11256.1.10.6.1';   # snsPowerSupplyEntry

# HA OIDs — structure: oid.<node_id>.<psu_id>
my $oid_psu_powered_ha = '.1.3.6.1.4.1.11256.1.11.10.1.2'; # snsNodePowerSupplyPowered
my $oid_psu_status_ha  = '.1.3.6.1.4.1.11256.1.11.10.1.3'; # snsNodePowerSupplyStatus
my $oid_psuEntry_ha    = '.1.3.6.1.4.1.11256.1.11.10.1';   # snsNodePowerSupplyEntry

sub load {
    my ($self) = @_;

    if ($self->{is_ha}) {
        push @{$self->{request}}, { oid => $oid_psuEntry_ha };
    } else {
        push @{$self->{request}}, { oid => $oid_psuEntry_single };
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking power supplies');
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    my $nodes   = $self->{is_ha} ? $self->{ha_nodes} : ['0'];
    my $serials = $self->{ha_serials};

    foreach my $node_id (@$nodes) {
        my $label_prefix = $self->{is_ha} ? $serials->{$node_id} . '_' : '';
        my %psus_data    = ();

        if ($self->{is_ha}) {
            foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_psuEntry_ha}})) {
                if ($oid =~ /^$oid_psu_powered_ha\.$node_id\.(\d+)$/) {
                    $psus_data{$1}{powered} = $self->{results}->{$oid_psuEntry_ha}->{$oid};
                } elsif ($oid =~ /^$oid_psu_status_ha\.$node_id\.(\d+)$/) {
                    $psus_data{$1}{status} = $self->{results}->{$oid_psuEntry_ha}->{$oid};
                }
            }
        } else {
            foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_psuEntry_single}})) {
                next if ($oid !~ /^$mapping_single->{status}->{oid}\.(\d+)$/);
                my $psu_id = $1;
                my $result = $self->{snmp}->map_instance(
                    mapping  => $mapping_single,
                    results  => $self->{results}->{$oid_psuEntry_single},
                    instance => $psu_id
                );
                $psus_data{$psu_id} = $result;
            }
        }

        foreach my $psu_id (sort { $a <=> $b } keys %psus_data) {
            my $psu      = $psus_data{$psu_id};
            my $instance = $label_prefix . 'psu' . $psu_id;

            next if ($self->check_filter(section => 'psu', instance => $instance));
            $self->{components}->{psu}->{total}++;

            my $status = $psu->{status} // 'unknown';

            $self->{output}->output_add(
                long_msg => sprintf(
                    "power supply '%s' status is '%s' [powered: %s]",
                    $instance,
                    $status,
                    (defined $psu->{powered} && $psu->{powered} == 1) ? 'yes' : 'no'
                )
            );

            my $exit = $self->get_severity(section => 'psu', value => $status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity  => $exit,
                    short_msg => sprintf("Power supply '%s' status is '%s'", $instance, $status)
                );
            }
        }
    }
}

1;