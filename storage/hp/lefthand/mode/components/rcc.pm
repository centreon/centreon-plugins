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

package storage::hp::lefthand::mode::components::rcc;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{components}->{rcc} = {name => 'raid controller caches', total => 0};
    $self->{output}->output_add(long_msg => "Checking raid controller cache");
    return if ($self->check_exclude('rcc'));
    
    my $rcc_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.90.0";
    my $rcc_name_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.91.1.2"; # begin .1
    my $rcc_state_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.91.1.90";
    my $rcc_status_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.91.1.91";
    my $bbu_enabled_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.91.1.50"; # 1 mean 'enabled'
    my $bbu_state_oid = '.1.3.6.1.4.1.9804.3.1.1.2.1.91.1.22';
    my $bbu_status_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.91.1.23"; # 1 mean 'ok'
    return if ($self->{global_information}->{$rcc_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$rcc_name_oid, $rcc_state_oid,
                                 $rcc_status_oid, $bbu_enabled_oid, $bbu_state_oid, $bbu_status_oid],
                        begin => 1, end => $self->{global_information}->{$rcc_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_raid = $self->{global_information}->{$rcc_count_oid};
    for (my $i = 1; $i <= $number_raid; $i++) {
        my $raid_name = $result->{$rcc_name_oid . "." . $i};
        my $raid_state = $result->{$rcc_state_oid . "." . $i};
        my $raid_status = $result->{$rcc_status_oid . "." . $i};
        my $bbu_enabled = $result->{$bbu_enabled_oid . "." . $i};
        my $bbu_state = $result->{$bbu_state_oid . "." . $i};
        my $bbu_status = $result->{$bbu_status_oid . "." . $i};
        
       $self->{components}->{rcc}->{total}++;
        
        if ($raid_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Raid Controller Caches '" .  $raid_name . "' problem '" . $raid_state . "'");
        }
        $self->{output}->output_add(long_msg => "Raid Controller Caches '" .  $raid_name . "' status = '" . $raid_status  . "', state = '" . $raid_state . "'");
        if ($bbu_enabled == 1) {
            if ($bbu_status != 1) {
                 $self->{output}->output_add(severity => 'CRITICAL', 
                                             short_msg => "BBU '" .  $raid_name . "' problem '" . $bbu_state . "'");
            }
            $self->{output}->output_add(long_msg => "   BBU status = '" . $bbu_status  . "', state = '" . $bbu_state . "'");
        } else {
            $self->{output}->output_add(long_msg => "   BBU disabled");
        }
    }
}

1;