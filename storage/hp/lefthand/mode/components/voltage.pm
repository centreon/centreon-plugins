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

package storage::hp::lefthand::mode::components::voltage;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
     $self->{components}->{voltage} = {name => 'voltage sensors', total => 0};
    $self->{output}->output_add(long_msg => "Checking voltage sensors");
    return if ($self->check_exclude('voltage'));
    
    my $vs_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.140.0";
    my $vs_name_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.141.1.2";
    my $vs_value_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.141.1.3";
    my $vs_low_limit_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.141.1.4";
    my $vs_high_limit_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.141.1.5";
    my $vs_state_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.141.1.90";
    my $vs_status_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.141.1.91";
    return if ($self->{global_information}->{$vs_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$vs_name_oid, $vs_value_oid,
                                 $vs_low_limit_oid, $vs_high_limit_oid,
                                 $vs_state_oid, $vs_status_oid],
                        begin => 1, end => $self->{global_information}->{$vs_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_vs = $self->{global_information}->{$vs_count_oid};
    for (my $i = 1; $i <= $number_vs; $i++) {
        my $vs_name = $result->{$vs_name_oid . "." . $i};
        my $vs_value = $result->{$vs_value_oid . "." . $i};
        my $vs_low_limit = $result->{$vs_low_limit_oid . "." . $i};
        my $vs_high_limit = $result->{$vs_high_limit_oid . "." . $i};
        my $vs_state = $result->{$vs_state_oid . "." . $i};
        my $vs_status = $result->{$vs_status_oid . "." . $i};
        
        $self->{components}->{voltage}->{total}++;
        
        # Check Voltage limit
        if (defined($vs_low_limit) && defined($vs_high_limit)) {
            if ($vs_value <= $vs_low_limit) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Voltage sensor '" .  $vs_name . "' too low");
            } elsif ($vs_value >= $vs_high_limit) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Voltage sensor '" .  $vs_name . "' too high");
            }
            $self->{output}->output_add(long_msg => "Voltage sensor '" .  $vs_name . "' value = '" . $vs_value  . "' (<= $vs_low_limit, >= $vs_high_limit)");
            $self->{output}->perfdata_add(label => $vs_name . "_volt",
                                          value => $vs_value,
                                          warning => '@:' . $vs_low_limit, critical => $vs_high_limit);
        }
        
        if ($vs_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Voltage sensor '" .  $vs_name . "' problem '" . $vs_state . "'");
        }
        $self->{output}->output_add(long_msg => "Voltage sensor '" .  $vs_name . "' status = '" . $vs_status  . "', state = '" . $vs_state . "'");
    }
}

1;