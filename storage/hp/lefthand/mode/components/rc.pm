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

package storage::hp::lefthand::mode::components::rc;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{components}->{rc} = {name => 'raid controllers', total => 0};
    $self->{output}->output_add(long_msg => "Checking raid controllers");
    return if ($self->check_exclude('rc'));
    
    my $rc_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.4.3.0";
    my $rc_name_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.4.1.2';
    my $rc_state_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.4.1.90';
    my $rc_status_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.4.1.91';
    return if ($self->{global_information}->{$rc_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$rc_name_oid, $rc_state_oid,
                                 $rc_status_oid],
                        begin => 1, end => $self->{global_information}->{$rc_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_rc = $self->{global_information}->{$rc_count_oid};
    for (my $i = 1; $i <= $number_rc; $i++) {
        my $rc_name = $result->{$rc_name_oid . "." . $i};
        my $rc_state = $result->{$rc_state_oid . "." . $i};
        my $rc_status = $result->{$rc_status_oid . "." . $i};
        
        $self->{components}->{rc}->{total}++;
        
        if ($rc_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Raid Device (Controller) '" .  $rc_name . "' problem '" . $rc_state . "'");
        }
        $self->{output}->output_add(long_msg => "Raid Device (Controller) '" .  $rc_name . "' status = '" . $rc_status  . "', state = '" . $rc_state . "'");
    }
}

1;