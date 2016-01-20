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

package storage::hp::lefthand::mode::components::ro;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{components}->{ro} = {name => 'raid os devices', total => 0};
    $self->{output}->output_add(long_msg => "Checking raid os devices");
    return if ($self->check_exclude('ro'));
    
    my $raid_os_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.4.50.0";
    my $raid_os_name_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.51.1.2';
    my $raid_os_state_oid = '.1.3.6.1.4.1.9804.3.1.1.2.4.51.1.90'; # != 'normal'
    return if ($self->{global_information}->{$raid_os_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$raid_os_name_oid, $raid_os_state_oid],
                        begin => 1, end => $self->{global_information}->{$raid_os_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_ro = $self->{global_information}->{$raid_os_count_oid};
    for (my $i = 1; $i <= $number_ro; $i++) {
        my $ro_name = $result->{$raid_os_name_oid . "." . $i};
        my $ro_state = $result->{$raid_os_state_oid . "." . $i};
        
        $self->{components}->{ro}->{total}++;
        
        if ($ro_state !~ /normal/i) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Raid OS Device '" .  $ro_name . "' problem '" . $ro_state . "'");
        }
        $self->{output}->output_add(long_msg => "Raid OS Device '" .  $ro_name . "' state = '" . $ro_state . "'");
    }
}

1;