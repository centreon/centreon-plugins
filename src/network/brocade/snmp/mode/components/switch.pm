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

package network::brocade::snmp::mode::components::switch;

use strict;
use warnings;

my %map_oper_status = (
    1 => 'online',
    2 => 'offline',
    3 => 'testing',
    4 => 'faulty'
);

my $mapping_global = {
    swFirmwareVersion   => { oid => '.1.3.6.1.4.1.1588.2.1.1.1.1.6' },
    swOperStatus        => { oid => '.1.3.6.1.4.1.1588.2.1.1.1.1.7', map => \%map_oper_status }
};
my $oid_swSystem = '.1.3.6.1.4.1.1588.2.1.1.1.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_swSystem, start => $mapping_global->{swFirmwareVersion}->{oid}, end => $mapping_global->{swOperStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking switch");
    $self->{components}->{switch} = {name => 'switch', total => 0, skip => 0};
    return if ($self->check_filter(section => 'switch'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_global, results => $self->{results}->{$oid_swSystem}, instance => '0');
    return if (!defined($result->{swOperStatus}));

    $self->{components}->{switch}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            "switch operational status is '%s' [firmware: %s].",
            $result->{swOperStatus}, $result->{swFirmwareVersion}
        )
    );
    my $exit = $self->get_severity(section => 'switch', value => $result->{swOperStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity =>  $exit,
            short_msg => sprintf(
                "switch operational status is '%s'",
                $result->{swOperStatus}
            )
        );
    }
}

1;