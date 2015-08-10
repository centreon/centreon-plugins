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

package hardware::server::cisco::ucs::mode::components::chassis;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw($thresholds);

sub check {
    my ($self) = @_;

    # In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
    $self->{output}->output_add(long_msg => "Checking chassis");
    $self->{components}->{chassis} = {name => 'chassis', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'chassis'));
    
    # Don't do the 'presence'. Is 'unknown' ??!!!
    my $oid_cucsEquipmentChassisOperState = '.1.3.6.1.4.1.9.9.719.1.15.7.1.27';
    my $oid_cucsEquipmentChassisDn = '.1.3.6.1.4.1.9.9.719.1.15.7.1.2';

    my $result = $self->{snmp}->get_multiple_table(oids => [ 
                                                            { oid => $oid_cucsEquipmentChassisOperState },
                                                            { oid => $oid_cucsEquipmentChassisDn },
                                                            ]
                                                   );
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_cucsEquipmentChassisOperState}})) {
        # index
        $key =~ /\.(\d+)$/;
        my $chassis_index = $1;        
        my $chassis_dn = $result->{$oid_cucsEquipmentChassisDn}->{$oid_cucsEquipmentChassisDn . '.' . $chassis_index};
        my $chassis_operstate = defined($result->{$oid_cucsEquipmentChassisOperState}->{$oid_cucsEquipmentChassisOperState . '.' . $chassis_index}) ?
                                $result->{$oid_cucsEquipmentChassisOperState}->{$oid_cucsEquipmentChassisOperState . '.' . $chassis_index} : 0; # unknown

        next if ($self->absent_problem(section => 'chassis', instance => $chassis_dn));
        next if ($self->check_exclude(section => 'chassis', instance => $chassis_dn));
        
        $self->{components}->{chassis}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("chassis '%s' state is '%s'.",
                                                        $chassis_dn, ${$thresholds->{operability}->{$chassis_operstate}}[0]
                                    ));
        my $exit = $self->get_severity(section => 'chassis', threshold => 'operability', value => $chassis_operstate);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("chassis '%s' state is '%s'.",
                                                             $chassis_dn, ${$thresholds->{operability}->{$chassis_operstate}}[0]
                                                             )
                                        );
        }
    }
}

1;
