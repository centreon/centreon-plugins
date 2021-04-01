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

package storage::dell::equallogic::snmp::mode::components::raid;

use strict;
use warnings;

my %map_raid_status = (
    1 => 'ok',
    2 => 'degraded',
    3 => 'verifying',
    4 => 'reconstructing',
    5 => 'failed',
    6 => 'catastrophicLoss',
    7 => 'expanding',
    8 => 'mirroring',
);

# In MIB 'eqlcontroller.mib'
my $mapping = {
    eqlMemberRaidStatus => { oid => '.1.3.6.1.4.1.12740.2.1.13.1.1', map => \%map_raid_status },
};
my $oid_eqlMemberRAIDEntry = '.1.3.6.1.4.1.12740.2.1.13.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_eqlMemberRAIDEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking raids");
    $self->{components}->{raid} = {name => 'raids', total => 0, skip => 0};
    return if ($self->check_filter(section => 'raid'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_eqlMemberRAIDEntry}})) {
        next if ($oid !~ /^$mapping->{eqlMemberRaidStatus}->{oid}\.(\d+\.\d+)$/);
        my ($member_instance) = ($1);
        my $member_name = $self->get_member_name(instance => $member_instance);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_eqlMemberRAIDEntry}, instance => $member_instance);

        next if ($self->check_filter(section => 'raid', instance => $member_instance));
        $self->{components}->{raid}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Raid '%s' status is %s [instance: %s].",
                                    $member_name, $result->{eqlMemberRaidStatus}, $member_instance
                                    ));
        my $exit = $self->get_severity(section => 'raid', value => $result->{eqlMemberRaidStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Raid '%s' status is %s",
                                                             $member_name, $result->{eqlMemberRaidStatus}));
        }
    }
}

1;