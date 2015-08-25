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

package hardware::server::cisco::ucs::mode::components::fan;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw($thresholds);

sub check {
    my ($self) = @_;

    # In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));
    
    my $oid_cucsEquipmentFanPresence = '.1.3.6.1.4.1.9.9.719.1.15.12.1.13';
    my $oid_cucsEquipmentFanOperState = '.1.3.6.1.4.1.9.9.719.1.15.12.1.9';
    my $oid_cucsEquipmentFanDn = '.1.3.6.1.4.1.9.9.719.1.15.12.1.2';

    my $result = $self->{snmp}->get_multiple_table(oids => [ 
                                                            { oid => $oid_cucsEquipmentFanPresence },
                                                            { oid => $oid_cucsEquipmentFanOperState },
                                                            { oid => $oid_cucsEquipmentFanDn },
                                                            ]
                                                   );
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_cucsEquipmentFanPresence}})) {
        # index
        $key =~ /\.(\d+)$/;
        my $fan_index = $1;        
        my $fan_dn = $result->{$oid_cucsEquipmentFanDn}->{$oid_cucsEquipmentFanDn . '.' . $fan_index};
        my $fan_operstate = defined($result->{$oid_cucsEquipmentFanOperState}->{$oid_cucsEquipmentFanOperState . '.' . $fan_index}) ?
                                $result->{$oid_cucsEquipmentFanOperState}->{$oid_cucsEquipmentFanOperState . '.' . $fan_index} : 0; # unknown
        my $fan_presence = defined($result->{$oid_cucsEquipmentFanPresence}->{$oid_cucsEquipmentFanPresence . '.' . $fan_index}) ? 
                                $result->{$oid_cucsEquipmentFanPresence}->{$oid_cucsEquipmentFanPresence . '.' . $fan_index} : 0;
        
        next if ($self->absent_problem(section => 'fan', instance => $fan_dn));
        next if ($self->check_exclude(section => 'fan', instance => $fan_dn));

        my $exit = $self->get_severity(section => 'fan', threshold => 'presence', value => $fan_presence);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("fan '%s' presence is: '%s'",
                                                             $fan_dn, ${$thresholds->{presence}->{$fan_presence}}[0])
                                        );
            next;
        }
        
        $self->{components}->{fan}->{total}++;      
        $self->{output}->output_add(long_msg => sprintf("fan '%s' state is '%s' [presence: %s].",
                                                        $fan_dn, ${$thresholds->{operability}->{$fan_operstate}}[0],
                                                        ${$thresholds->{presence}->{$fan_presence}}[0]
                                    ));
        $exit = $self->get_severity(section => 'fan', threshold => 'operability', value => $fan_operstate);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("fan '%s' state is '%s'.",
                                                             $fan_dn, ${$thresholds->{operability}->{$fan_operstate}}[0]
                                                             )
                                        );
        }
    }
}

1;