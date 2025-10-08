#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package snmp_standard::mode::components::unit;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $map_unit_status = {
    1 => 'unknown', 2 => 'unused', 3 => 'ok', 4 => 'warning', 5 => 'failed'
};
my $map_unit_type = {
    1 => 'unknown', 2 => 'other', 3 => 'hub', 4 => 'switch', 5 => 'gateway',
    6 => 'converter', 7 => 'hba', 8 => 'proxy-agent', 9 => 'storage-device',
    10 => 'host', 11 => 'storage-subsystem', 12 => 'module', 13 => 'swdriver',
    14 => 'storage-access-device', 15 => 'wdm', 16 => 'ups', 17 => 'nas'
};

my $mapping_unit = {
    connUnitType   => { oid => '.1.3.6.1.3.94.1.6.1.3', map => $map_unit_type },
    connUnitStatus => { oid => '.1.3.6.1.3.94.1.6.1.6', map => $map_unit_status },
    connUnitName   => { oid => '.1.3.6.1.3.94.1.6.1.20' }
};

sub load {
    my ($self) = @_;

    push @{$self->{request}},
        { oid => $mapping_unit->{connUnitType}->{oid} },
        { oid => $mapping_unit->{connUnitStatus}->{oid} },
        { oid => $mapping_unit->{connUnitName}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking units");
    $self->{components}->{unit} = { name => 'units', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'unit'));

    my $results = {
        %{$self->{results}->{ $mapping_unit->{connUnitType}->{oid} }},
        %{$self->{results}->{ $mapping_unit->{connUnitStatus}->{oid} }},
        %{$self->{results}->{ $mapping_unit->{connUnitName}->{oid} }},
    };
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$results)) {
        next if ($key !~ /^$mapping_unit->{connUnitName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_unit, results => $results, instance => $instance);
        my $name = $result->{connUnitType} . '.' . $result->{connUnitName};

        next if ($self->check_filter(section => 'unit', instance => $instance, name => $name));

        $self->{components}->{unit}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "unit '%s' status is %s",
                $name, $result->{connUnitStatus}
            )
        );
        my $exit = $self->get_severity(section => 'unit', instance => $instance, name => $name, value => $result->{connUnitStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Unit '%s' status is %s",
                    $name,
                    $result->{connUnitStatus}
                )
            );
        }
    }
}

1;