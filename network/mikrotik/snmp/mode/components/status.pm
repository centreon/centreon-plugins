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

package network::mikrotik::snmp::mode::components::status;

use strict;
use warnings;
use network::mikrotik::snmp::mode::components::resources qw($map_gauge_unit $mapping_gauge);

my $mapping = {
    mtxrHlPowerSupplyState       => { oid => '.1.3.6.1.4.1.14988.1.1.3.15' },
    mtxrHlBackupPowerSupplyState => { oid => '.1.3.6.1.4.1.14988.1.1.3.16' }
};

sub load {}

sub check_status {
    my ($self, %options) = @_;

    $self->{output}->output_add(
        long_msg => sprintf(
            "status '%s' is %s",
            $options{name},
            $options{value}
        )
    );

    my $exit = $self->get_severity(section => 'status', value => $options{value});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf("Status '%s' is %s", $options{name}, $options{value})
        );
    }
    $self->{components}->{status}->{total}++;
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking status");
    $self->{components}->{status} = {name => 'status', total => 0, skip => 0};
    return if ($self->check_filter(section => 'status'));

    foreach (keys %{$self->{results}}) {
        next if (! /^$mapping_gauge->{unit}->{oid}\.(\d+)/);
        next if ($map_gauge_unit->{ $self->{results}->{$_} } ne 'status');
        my $result = $self->{snmp}->map_instance(mapping => $mapping_gauge, results => $self->{results}, instance => $1);
        next if ($self->check_filter(section => 'status', instance => $result->{name}));
        check_status(
            $self,
            value => $result->{value} == 0 ? 'ok' : 'not ok',
            name => $result->{name}
        );
    }

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => 0);
    if (defined($result->{mtxrHlPowerSupplyState}) && ! $self->check_filter(section => 'status', instance => 'psu-primary')) {
        check_status(
            $self,
            value => $result->{mtxrHlPowerSupplyState} == 1 ? 'ok' : 'not ok',
            name => 'psu-primary'
        );
    }
    if (defined($result->{mtxrHlBackupPowerSupplyState}) && ! $self->check_filter(section => 'status', instance => 'psu-backup')) {
        check_status(
            $self,
            value => $result->{mtxrHlBackupPowerSupplyState} == 1 ? 'ok' : 'not ok',
            name => 'psu-backup'
        );
    }
}

1;
