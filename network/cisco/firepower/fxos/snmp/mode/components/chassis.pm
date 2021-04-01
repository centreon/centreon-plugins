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

package network::cisco::firepower::fxos::snmp::mode::components::chassis;

use strict;
use warnings;
use network::cisco::firepower::fxos::snmp::mode::components::resources qw($map_operability);

my $mapping = {
    dn          => { oid => '.1.3.6.1.4.1.9.9.826.1.20.21.1.2' }, # cfprEquipmentChassisDn
    operability => { oid => '.1.3.6.1.4.1.9.9.826.1.20.21.1.31', map => $map_operability } # cfprEquipmentChassisOperability
};
my $mapping_stats = {
    dn           => { oid => '.1.3.6.1.4.1.9.9.826.1.20.26.1.2' }, # cfprEquipmentChassisStatsDn
    input_power  => { oid => '.1.3.6.1.4.1.9.9.826.1.20.26.1.5' }, # cfprEquipmentChassisStatsInputPowerAvg
    output_power => { oid => '.1.3.6.1.4.1.9.9.826.1.20.26.1.10' }  # cfprEquipmentChassisStatsOutputPowerAvg
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, map({ oid => $_->{oid} }, values(%$mapping), values(%$mapping_stats));
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking chassis");
    $self->{components}->{chassis} = { name => 'chassis', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'chassis'));

    my $results = { map(%{$self->{results}->{ $_->{oid} }}, values(%$mapping)) };
    my $results_stats = { map(%{$self->{results}->{ $_->{oid} }}, values(%$mapping_stats)) };

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$results)) {
        next if ($oid !~ /^$mapping->{operability}->{oid}\.(.*)$/);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results, instance => $1);

        next if ($self->check_filter(section => 'chassis', instance => $result->{dn}));
        $self->{components}->{chassis}->{total}++;

        my $result_stats = $self->compare_dn(
            regexp => "^$result->{dn}/",
            lookup => 'dn',
            results => $results_stats,
            mapping => $mapping_stats
        );

        $self->{output}->output_add(
            long_msg => sprintf(
                "chassis '%s' status is '%s' [input power: %s W, output power: %s W].",
                $result->{dn},
                $result->{operability},
                $result_stats->{input_power},
                $result_stats->{output_power},
            )
        );
        $exit = $self->get_severity(label => 'operability', section => 'chassis', instance => $result->{dn}, value => $result->{operability});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "chassis '%s' status is '%s'",
                    $result->{dn},
                    $result->{operability}
                )
            );
        }

        foreach (('input', 'output')) {
            ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'chassis.' . $_ . 'power', instance => $result->{dn}, value => $result_stats->{$_ . '_power'});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "chassis '%s' %s power is %s W",
                        $result->{dn},
                        $result_stats->{$_ . '_power'}
                    )
                );
            }
            $self->{output}->perfdata_add(
                nlabel => 'hardware.chassis.' . $_ . '.power.watt',
                unit => 'W',
                instances => $result->{dn},
                value => $result_stats->{$_ . '_power'},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
