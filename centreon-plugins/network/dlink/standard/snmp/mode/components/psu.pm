#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::dlink::standard::snmp::mode::components::psu;

use strict;
use warnings;
use centreon::plugins::misc;

my $map_status_equipment = {
    0 => 'other', 1 => 'lowVoltage', 2 => 'overCurrent',
    3 => 'working', 4 => 'fail', 5 => 'connect',
    6 => 'disconnect'
};
my $map_status = {
    1 => 'inOperation', 2 => 'failed', 3 => 'empty'
};

my $mapping_equipment = {
    status => { oid => '.1.3.6.1.4.1.171.12.11.1.6.1.3', map => $map_status_equipment } # swPowerStatus
};
my $mapping_industrial = {
    description => { oid => '.1.3.6.1.4.1.171.14.5.1.1.3.1.3' }, # dEntityExtEnvPowerDescr
    status      => { oid => '.1.3.6.1.4.1.171.14.5.1.1.3.1.6', map => $map_status } # dEntityExtEnvPowerStatus
};
my $oid_dEntityExtEnvPowerEntry = '.1.3.6.1.4.1.171.14.5.1.1.3.1';

my $mapping_common = {
    description => { oid => '.1.3.6.1.4.1.171.17.5.1.1.3.1.3' }, # esEntityExtEnvPowerDescr
    status      => { oid => '.1.3.6.1.4.1.171.17.5.1.1.3.1.6', map => $map_status } # esEntityExtEnvPowerStatus
};
my $oid_esEntityExtEnvPowerEntry = '.1.3.6.1.4.1.171.17.5.1.1.3.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}},
        { oid => $mapping_equipment->{status}->{oid} },
        { oid => $oid_dEntityExtEnvPowerEntry, start => $mapping_industrial->{description}->{oid} },
        { oid => $oid_esEntityExtEnvPowerEntry, start => $mapping_common->{description}->{oid} }
    ;
}

sub check_psu {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $options{entry} }})) {
        next if ($oid !~ /^$options{mapping}->{status}->{oid}\.(\d+)\.(\d+)$/);
        my ($unit_id, $psu_id) = ($1, $2);
        my $instance = $1 . '.' . $2;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{ $options{entry} }, instance => $instance);

        my $description = 'unit' . $unit_id . ':psu' . $psu_id;
        next if ($self->check_filter(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' status is '%s' [instance: %s, description: %s]",
                $description,
                $result->{status},
                $instance,
                defined($result->{description}) ? centreon::plugins::misc::trim($result->{description}) : '-'
            )
        );
        my $exit = $self->get_severity(section => 'psu', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Power supply '%s' status is '%s'",
                    $description, $result->{status}
                )
            );
        }
    }
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking power supplies');
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    check_psu($self, entry => $mapping_equipment->{status}->{oid}, mapping => $mapping_equipment);
    check_psu($self, entry => $oid_dEntityExtEnvPowerEntry, mapping => $mapping_industrial);
    check_psu($self, entry => $oid_esEntityExtEnvPowerEntry, mapping => $mapping_common);
}

1;
