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

package hardware::kvm::avocent::acs::6000::snmp::mode::components::psu;

use strict;
use warnings;

my %map_states = (1 => 'statePowerOn', 2 => 'statePowerOff', 9999 => 'powerNotInstalled');

my $mapping = {
    acsPowerSupplyStatePw1 => { oid => '.1.3.6.1.4.1.10418.16.2.1.8.2', map => \%map_states },
    acsPowerSupplyStatePw2 => { oid => '.1.3.6.1.4.1.10418.16.2.1.8.3', map => \%map_states },
};
my $oid_acsPowerSupply = '.1.3.6.1.4.1.10418.16.2.1.8';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_acsPowerSupply };
}

sub check_psu {
    my ($self, %options) = @_;

    return if ($self->check_filter(section => 'psu', instance => $options{instance}));
    return if ($options{state} eq 'powerNotInstalled' && 
               $self->absent_problem(section => 'psu', instance => $options{instance}));
    $self->{components}->{psu}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            "power supply '%s' status is %s.",
            $options{instance}, $options{state}
        )
    );

    my $exit = $self->get_severity(section => 'psu', value => $options{state});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity =>  $exit,
            short_msg => sprintf(
                "Power supply '%s' status is %s",
                $options{instance},
                $options{state}
            )
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_acsPowerSupply}, instance => '0');
    check_psu($self, state => $result->{acsPowerSupplyStatePw1}, instance => '1');
    check_psu($self, state => $result->{acsPowerSupplyStatePw2}, instance => '2');
}

1;
