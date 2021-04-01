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

package storage::netapp::ontap::snmp::mode::components::raid;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_raid_states = (
    1 => 'active',
    2 => 'reconstructionInProgress',
    3 => 'parityReconstructionInProgress',
    4 => 'parityVerificationInProgress',
    5 => 'scrubbingInProgress',
    6 => 'failed',
    9 => 'prefailed',
    10 => 'offline',
);
my $oid_raidPStatus = '.1.3.6.1.4.1.789.1.6.10.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_raidPStatus };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking raids");
    $self->{components}->{raid} = {name => 'raids', total => 0, skip => 0};
    return if ($self->check_filter(section => 'raid'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_raidPStatus}})) {
        $oid =~ /^$oid_raidPStatus\.(.*)$/;
        my $instance = $1;
        my $raid_state = $map_raid_states{$self->{results}->{$oid_raidPStatus}->{$oid}};

        next if ($self->check_filter(section => 'raid', instance => $instance));
        
        $self->{components}->{raid}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Raid '%s' state is '%s'", 
                                                        $instance, $raid_state));
        my $exit = $self->get_severity(section => 'raid', value => $raid_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Raid '%s' state is '%s'", 
                                                             $instance, $raid_state));
        }
    }
}

1;
