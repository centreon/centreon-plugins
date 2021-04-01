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

package storage::dell::equallogic::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (
    1 => 'on-and-operating', 
    2 => 'no-ac-power', 
    3 => 'failed-or-no-data', 
);
my %map_psufan_status = (
    0 => 'not-applicable', 
    1 => 'fan-is-operational', 
    2 => 'fan-not-operational', 
);

# In MIB 'eqlcontroller.mib'
my $mapping = {
    eqlMemberHealthDetailsPowerSupplyName  => { oid => '.1.3.6.1.4.1.12740.2.1.8.1.2' },
    eqlMemberHealthDetailsPowerSupplyCurrentState => { oid => '.1.3.6.1.4.1.12740.2.1.8.1.3', map => \%map_psu_status },
    eqlMemberHealthDetailsPowerSupplyFanStatus => { oid => '.1.3.6.1.4.1.12740.2.1.8.1.4', map => \%map_psufan_status },
};
my $oid_eqlMemberHealthDetailsPowerSupplyEntry = '.1.3.6.1.4.1.12740.2.1.8.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_eqlMemberHealthDetailsPowerSupplyEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'power supplies', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_eqlMemberHealthDetailsPowerSupplyEntry}})) {
        next if ($oid !~ /^$mapping->{eqlMemberHealthDetailsPowerSupplyCurrentState}->{oid}\.(\d+\.\d+)\.(.*)$/);
        my ($member_instance, $instance) = ($1, $2);
        my $member_name = $self->get_member_name(instance => $member_instance);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_eqlMemberHealthDetailsPowerSupplyEntry}, instance => $member_instance . '.' . $instance);

        next if ($self->check_filter(section => 'psu', instance => $member_instance . '.' . $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s/%s' status is %s [instance: %s] [fan status: %s].",
                                    $member_name, $result->{eqlMemberHealthDetailsPowerSupplyName}, $result->{eqlMemberHealthDetailsPowerSupplyCurrentState},
                                    $member_instance . '.' . $instance, $result->{eqlMemberHealthDetailsPowerSupplyFanStatus}
                                    ));
        my $exit = $self->get_severity(section => 'psu', value => $result->{eqlMemberHealthDetailsPowerSupplyCurrentState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Power supply '%s/%s' status is %s",
                                                             $member_name, $result->{eqlMemberHealthDetailsPowerSupplyName}, $result->{eqlMemberHealthDetailsPowerSupplyCurrentState}));
        }

        next if ($self->check_filter(section => 'psu.fan', instance => $member_instance . '.' . $instance));
        $exit = $self->get_severity(section => 'psu.fan', value => $result->{eqlMemberHealthDetailsPowerSupplyFanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Power supply '%s/%s' fan status is %s",
                                                             $member_name, $result->{eqlMemberHealthDetailsPowerSupplyName}, $result->{eqlMemberHealthDetailsPowerSupplyFanStatus}));
        }
    }
}

1;