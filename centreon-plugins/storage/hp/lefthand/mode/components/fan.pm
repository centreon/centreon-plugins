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

package storage::hp::lefthand::mode::components::fan;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{components}->{fan} = {name => 'fans', total => 0};
    $self->{output}->output_add(long_msg => "Checking fan");
    return if ($self->check_exclude('fan'));
    
    my $fan_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.110.0"; # 0 means 'none'
    my $fan_name_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.111.1.2"; # begin .1
    my $fan_speed_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.111.1.3"; # dont have
    my $fan_min_speed_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.111.1.4"; # dont have
    my $fan_state_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.111.1.90"; # string explained
    my $fan_status_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.111.1.91";
    return if ($self->{global_information}->{$fan_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$fan_name_oid, $fan_name_oid,
                                 $fan_min_speed_oid, $fan_state_oid, $fan_status_oid],
                        begin => 1, end => $self->{global_information}->{$fan_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_fans = $self->{global_information}->{$fan_count_oid};
    for (my $i = 1; $i <= $number_fans; $i++) {
        my $fan_name = $result->{$fan_name_oid . "." . $i};
        my $fan_speed = $result->{$fan_speed_oid . "." . $i};
        my $fan_min_speed = $result->{$fan_min_speed_oid . "." . $i};
        my $fan_status = $result->{$fan_status_oid . "." . $i};
        my $fan_state = $result->{$fan_state_oid . "." . $i};
    
        $self->{components}->{fan}->{total}++;
    
        # Check Fan Speed
        if (defined($fan_speed)) {
            my $low_limit = '';
            if (defined($fan_min_speed)) {
                $low_limit = '@:' . $fan_min_speed;
                if ($fan_speed <= $fan_min_speed) {
                    $self->{output}->output_add(severity => 'CRITICAL', 
                                                short_msg => "Fan '" .  $fan_name . "' speed too low");
                }
            }
            $self->{output}->output_add(long_msg => "Fan '" .  $fan_name . "' speed = '" . $fan_speed  . "' (<= $fan_min_speed)");
            $self->{output}->perfdata_add(label => $fan_name, unit => 'rpm',
                                          value => $fan_speed,
                                          critical => $low_limit);            
        }
        
        if ($fan_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Fan '" .  $fan_name . "' problem '" . $fan_state . "'");
        }
        $self->{output}->output_add(long_msg => "Fan '" .  $fan_name . "' status = '" . $fan_status  . "', state = '" . $fan_state . "'");
    }
}

1;