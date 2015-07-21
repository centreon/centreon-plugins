#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::juniper::common::screenos::mode::components::module;

use strict;
use warnings;

my %map_status = (
    1 => 'active',
    2 => 'inactive'
);

sub check {
    my ($self) = @_;

    $self->{components}->{modules} = {name => 'modules', total => 0};
    $self->{output}->output_add(long_msg => "Checking modules");
    return if ($self->check_exclude(section => 'modules'));
    
    my $oid_nsSlotEntry = '.1.3.6.1.4.1.3224.21.5.1';
    my $oid_nsSlotType = '.1.3.6.1.4.1.3224.21.5.1.2';
    my $oid_nsSlotStatus = '.1.3.6.1.4.1.3224.21.5.1.3';
    
    my $result = $self->{snmp}->get_table(oid => $oid_nsSlotEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_nsSlotStatus\.(\d+)$/);
        my $instance = $1;
    
        next if ($self->check_exclude(section => 'modules', instance => $instance));
    
        my $type = $result->{$oid_nsSlotType . '.' . $instance};
        my $status = $result->{$oid_nsSlotStatus . '.' . $instance};

        $self->{components}->{modules}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Module '%s' status is %s [instance: %s].", 
                                    $type, $map_status{$status}, $instance));
        if ($status != 1) {
            $self->{output}->output_add(severity =>  'CRITICAL',
                                        short_msg => sprintf("Module '%s' status is %s", 
                                                             $type, $map_status{$status}));
        }
    }
}

1;
