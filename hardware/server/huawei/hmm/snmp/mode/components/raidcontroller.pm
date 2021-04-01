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

package hardware::server::huawei::hmm::snmp::mode::components::raidcontroller;

use strict;
use warnings;

my %map_status = (
    1 => 'normal',
    2 => 'minor',
    3 => 'major',
    4 => 'critical',
);

my %map_installation_status = (
    1 => 'absent',
    2 => 'present',
);

my $mapping = {
    bladeRAIDControllerIndex            => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2011.1.1' },
    bladeRAIDControllerPresence         => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2011.1.2', map => \%map_installation_status },
    bladeRAIDControllerHealthState      => { oid => '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2011.1.7', map => \%map_status },
};
my $oid_bladeRAIDControllerTable = '.1.3.6.1.4.1.2011.2.82.1.82.4.#.2011.1';

sub load {
    my ($self) = @_;

    $oid_bladeRAIDControllerTable =~ s/#/$self->{blade_id}/;
    push @{$self->{request}}, { oid => $oid_bladeRAIDControllerTable };
}

sub check {
    my ($self) = @_;

    foreach my $entry (keys $mapping) {
        $mapping->{$entry}->{oid} =~ s/#/$self->{blade_id}/;
    }

    $self->{output}->output_add(long_msg => "Checking RAID controllers");
    $self->{components}->{raidcontroller} = {name => 'raid controllers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'raidcontroller'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_bladeRAIDControllerTable}})) {
        next if ($oid !~ /^$mapping->{bladeRAIDControllerHealthState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_bladeRAIDControllerTable}, instance => $instance);

        next if ($self->check_filter(section => 'raidcontroller', instance => $instance));
        next if ($result->{bladeRAIDControllerPresence} !~ /present/);
        $self->{components}->{raidcontroller}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Raid controller '%s' status is '%s' [instance = %s]",
                                    $result->{bladeRAIDControllerIndex}, $result->{bladeRAIDControllerHealthState}, $instance, 
                                    ));
   
        my $exit = $self->get_severity(label => 'default', section => 'raidcontroller', value => $result->{bladeRAIDControllerHealthState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Raid controller '%s' status is '%s'", $result->{bladeRAIDControllerIndex}, $result->{bladeRAIDControllerHealthState}));
        }
    }
}

1;