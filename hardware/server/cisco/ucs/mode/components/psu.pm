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

package hardware::server::cisco::ucs::mode::components::psu;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw($thresholds);

sub check {
    my ($self) = @_;

    # In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));
    
    my $oid_cucsEquipmentPsuPresence = '.1.3.6.1.4.1.9.9.719.1.15.56.1.11';
    my $oid_cucsEquipmentPsuOperState = '.1.3.6.1.4.1.9.9.719.1.15.56.1.7';
    my $oid_cucsEquipmentPsuDn = '.1.3.6.1.4.1.9.9.719.1.15.56.1.2';

    my $result = $self->{snmp}->get_multiple_table(oids => [ 
                                                            { oid => $oid_cucsEquipmentPsuPresence },
                                                            { oid => $oid_cucsEquipmentPsuOperState },
                                                            { oid => $oid_cucsEquipmentPsuDn },
                                                            ]
                                                   );
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_cucsEquipmentPsuPresence}})) {
        # index
        $key =~ /\.(\d+)$/;
        my $psu_index = $1;        
        my $psu_dn = $result->{$oid_cucsEquipmentPsuDn}->{$oid_cucsEquipmentPsuDn . '.' . $psu_index};
        my $psu_operstate = defined($result->{$oid_cucsEquipmentPsuOperState}->{$oid_cucsEquipmentPsuOperState . '.' . $psu_index}) ?
                                $result->{$oid_cucsEquipmentPsuOperState}->{$oid_cucsEquipmentPsuOperState . '.' . $psu_index} : 0; # unknown
        my $psu_presence = defined($result->{$oid_cucsEquipmentPsuPresence}->{$oid_cucsEquipmentPsuPresence . '.' . $psu_index}) ? 
                                $result->{$oid_cucsEquipmentPsuPresence}->{$oid_cucsEquipmentPsuPresence . '.' . $psu_index} : 0;
        
        next if ($self->absent_problem(section => 'psu', instance => $psu_dn));
        next if ($self->check_exclude(section => 'psu', instance => $psu_dn));

         my $exit = $self->get_severity(section => 'psu', threshold => 'presence', value => $psu_presence);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("power supply '%s' presence is: '%s'",
                                                             $psu_dn, ${$thresholds->{presence}->{$psu_presence}}[0])
                                        );
            next;
        }
        
        $self->{components}->{psu}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("power supply '%s' state is '%s' [presence: %s].",
                                                        $psu_dn, ${$thresholds->{operability}->{$psu_operstate}}[0],
                                                        ${$thresholds->{presence}->{$psu_presence}}[0]
                                    ));
        $exit = $self->get_severity(section => 'psu', threshold => 'operability', value => $psu_operstate);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("power supply '%s' state is '%s'.",
                                                             $psu_dn, ${$thresholds->{operability}->{$psu_operstate}}[0]
                                                             )
                                        );
        }
    }
}

1;
