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

package hardware::server::cisco::ucs::mode::components::iocard;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw($thresholds);

sub check {
    my ($self) = @_;

    # In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
    $self->{output}->output_add(long_msg => "Checking io cards");
    $self->{components}->{iocard} = {name => 'io cards', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'iocard'));
    
    my $oid_cucsEquipmentIOCardPresence = '.1.3.6.1.4.1.9.9.719.1.15.30.1.31';
    my $oid_cucsEquipmentIOCardOperState = '.1.3.6.1.4.1.9.9.719.1.15.30.1.25';
    my $oid_cucsEquipmentIOCardDn = '.1.3.6.1.4.1.9.9.719.1.15.30.1.2';

    my $result = $self->{snmp}->get_multiple_table(oids => [ 
                                                            { oid => $oid_cucsEquipmentIOCardPresence },
                                                            { oid => $oid_cucsEquipmentIOCardOperState },
                                                            { oid => $oid_cucsEquipmentIOCardDn },
                                                            ]
                                                   );
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_cucsEquipmentIOCardPresence}})) {
        # index
        $key =~ /\.(\d+)$/;
        my $iocard_index = $1;        
        my $iocard_dn = $result->{$oid_cucsEquipmentIOCardDn}->{$oid_cucsEquipmentIOCardDn . '.' . $iocard_index};
        my $iocard_operstate = defined($result->{$oid_cucsEquipmentIOCardOperState}->{$oid_cucsEquipmentIOCardOperState . '.' . $iocard_index}) ?
                                $result->{$oid_cucsEquipmentIOCardOperState}->{$oid_cucsEquipmentIOCardOperState . '.' . $iocard_index} : 0; # unknown
        my $iocard_presence = defined($result->{$oid_cucsEquipmentIOCardPresence}->{$oid_cucsEquipmentIOCardPresence . '.' . $iocard_index}) ? 
                                $result->{$oid_cucsEquipmentIOCardPresence}->{$oid_cucsEquipmentIOCardPresence . '.' . $iocard_index} : 0;
        
        next if ($self->absent_problem(section => 'iocard', instance => $iocard_dn));
        next if ($self->check_exclude(section => 'iocard', instance => $iocard_dn));

        my $exit = $self->get_severity(section => 'iocard', threshold => 'presence', value => $iocard_presence);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("IO cards '%s' presence is: '%s'",
                                                             $iocard_dn, ${$thresholds->{presence}->{$iocard_presence}}[0])
                                        );
            next;
        }
        
        $self->{components}->{iocard}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("IO cards '%s' state is '%s' [presence: %s].",
                                                        $iocard_dn, ${$thresholds->{operability}->{$iocard_operstate}}[0],
                                                        ${$thresholds->{presence}->{$iocard_presence}}[0]
                                    ));
        $exit = $self->get_severity(section => 'iocard', threshold => 'operability', value => $iocard_operstate);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("IO cards '%s' state is '%s'.",
                                                             $iocard_dn, ${$thresholds->{operability}->{$iocard_operstate}}[0]
                                                             )
                                        );
        }
    }
}

1;
