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

package network::perle::ids::snmp::mode::components::psu;

use strict;
use warnings;
use network::perle::ids::snmp::mode::components::resources qw($map_status);

my $mapping = {
    perleEnvMonPowerSupplyStatusDescr  => { oid => '.1.3.6.1.4.1.1966.22.12.1.1.1.2' },
    perleEnvMonPowerSupplyState        => { oid => '.1.3.6.1.4.1.1966.22.12.1.1.1.3', map => $map_status },
};
my $oid_perleEnvMonPowerSupplyStatusEntry = '.1.3.6.1.4.1.1966.22.12.1.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_perleEnvMonPowerSupplyStatusEntry, 
        start => $mapping->{perleEnvMonPowerSupplyStatusDescr}->{oid},
        end => $mapping->{perleEnvMonPowerSupplyState}->{oid},
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_perleEnvMonPowerSupplyStatusEntry}})) {
        next if ($oid !~ /^$mapping->{perleEnvMonPowerSupplyState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_perleEnvMonPowerSupplyStatusEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'psu', instance => $instance, name => $result->{perleEnvMonPowerSupplyStatusDescr}));
        next if ($result->{perleEnvMonPowerSupplyState} =~ /notPresent/i &&
                 $self->absent_problem(section => 'psu', instance => $instance, name => $result->{perleEnvMonPowerSupplyStatusDescr}));
        
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("power supply '%s' status is '%s' [instance = %s]",
                                                        $result->{perleEnvMonPowerSupplyStatusDescr}, $result->{perleEnvMonPowerSupplyState}, $instance));
        my $exit = $self->get_severity(label => 'default', section => 'psu', name => $result->{perleEnvMonPowerSupplyStatusDescr}, value => $result->{perleEnvMonPowerSupplyState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is '%s'", $result->{perleEnvMonPowerSupplyStatusDescr}, $result->{perleEnvMonPowerSupplyState}));
        }
    }
}

1;
