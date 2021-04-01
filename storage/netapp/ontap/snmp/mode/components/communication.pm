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

package storage::netapp::ontap::snmp::mode::components::communication;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_com_states = (
    1 => 'initializing', 
    2 => 'transitioning', 
    3 => 'active', 
    4 => 'inactive',
    5 => 'reconfiguring',
    6 => 'nonexistent',
);
my $oid_enclChannelShelfAddr = '.1.3.6.1.4.1.789.1.21.1.2.1.3';
my $oid_enclContactState = '.1.3.6.1.4.1.789.1.21.1.2.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_enclContactState };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking communications");
    $self->{components}->{communication} = {name => 'communications', total => 0, skip => 0};
    return if ($self->check_filter(section => 'communication'));

    for (my $i = 1; $i <= $self->{number_shelf}; $i++) {
        my $shelf_addr = $self->{shelf_addr}->{$oid_enclChannelShelfAddr . '.' . $i};
        my $com_state = $map_com_states{$self->{results}->{$oid_enclContactState}->{$oid_enclContactState . '.' . $i}};

        next if ($self->check_filter(section => 'communication', instance => $shelf_addr));
        
        $self->{components}->{communication}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Shelve '%s' communication state is '%s'", 
                                                          $shelf_addr, $com_state));
        my $exit = $self->get_severity(section => 'communication', value => $com_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Shelve '%s' communication state is '%s'", 
                                                          $shelf_addr, $com_state));
        }
    }
}

1;
