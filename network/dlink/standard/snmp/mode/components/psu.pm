#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

my %map_states = (
    0 => 'other',
    1 => 'lowVoltage',
    2 => 'overCurrent',
    3 => 'working',
    4 => 'fail',
    5 => 'connect',
    6 => 'disconnect',
);

# In MIB 'equipment.mib'
my $mapping = {
    swPowerStatus => { oid => '.1.3.6.1.4.1.171.12.11.1.6.1.3', map => \%map_states },
};
my $oid_swPowerEntry = '.1.3.6.1.4.1.171.12.11.1.6.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_swPowerEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_swPowerEntry}})) {
        next if ($oid !~ /^$mapping->{swPowerStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_swPowerEntry}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is %s.",
                                    $instance, $result->{swPowerStatus}
                                    ));
        my $exit = $self->get_severity(section => 'psu', value => $result->{swPowerStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Power supply '%s' status is %s",
                                                             $instance, $result->{swPowerStatus}));
        }
    }
}

1;