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

package storage::hp::lefthand::mode::components::psu;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    $self->{components}->{psu} = {name => 'power supplies', total => 0};
    $self->{output}->output_add(long_msg => "Checking power supplies");
    return if ($self->check_exclude('psu'));
    
    my $power_supply_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.130.0";
    my $power_supply_name_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.131.1.2";
    my $power_supply_state_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.131.1.90";
    my $power_supply_status_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.131.1.91";
    return if ($self->{global_information}->{$power_supply_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$power_supply_name_oid, $power_supply_name_oid,
                                 $power_supply_status_oid],
                        begin => 1, end => $self->{global_information}->{$power_supply_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_ps = $self->{global_information}->{$power_supply_count_oid};
    for (my $i = 1; $i <= $number_ps; $i++) {
        my $ps_name = $result->{$power_supply_name_oid . "." . $i};
        my $ps_state = $result->{$power_supply_state_oid . "." . $i};
        my $ps_status = $result->{$power_supply_status_oid . "." . $i};
        
        $self->{components}->{psu}->{total}++;
        
        if ($ps_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Power Supply '" .  $ps_name . "' problem '" . $ps_state . "'");
        }
        $self->{output}->output_add(long_msg => "Power Supply '" .  $ps_name . "' status = '" . $ps_status  . "', state = '" . $ps_state . "'");
    }
}

1;