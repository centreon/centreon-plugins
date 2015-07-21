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

package hardware::server::cisco::ucs::mode::components::fex;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw($thresholds);

sub check {
    my ($self) = @_;

    # In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
    $self->{output}->output_add(long_msg => "Checking fabric extenders");
    $self->{components}->{fex} = {name => 'fabric extenders', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fex'));
    
    my $oid_cucsEquipmentFexDn = '.1.3.6.1.4.1.9.9.719.1.15.19.1.2';
    my $oid_cucsEquipmentFexOperState = '.1.3.6.1.4.1.9.9.719.1.15.19.1.21';
    my $oid_cucsEquipmentFexPresence = '.1.3.6.1.4.1.9.9.719.1.15.19.1.24';

    my $result = $self->{snmp}->get_multiple_table(oids => [ 
                                                            { oid => $oid_cucsEquipmentFexDn },
                                                            { oid => $oid_cucsEquipmentFexOperState },
                                                            { oid => $oid_cucsEquipmentFexPresence },
                                                            ]
                                                   );
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_cucsEquipmentFexDn}})) {
        # index
        $key =~ /\.(\d+)$/;
        my $fex_index = $1;
        my $fex_dn = $result->{$oid_cucsEquipmentFexDn}->{$oid_cucsEquipmentFexDn . '.' . $fex_index};
        my $fex_operstate = defined($result->{$oid_cucsEquipmentFexOperState}->{$oid_cucsEquipmentFexOperState . '.' . $fex_index}) ?
                                $result->{$oid_cucsEquipmentFexOperState}->{$oid_cucsEquipmentFexOperState . '.' . $fex_index} : 0; # unknown
        my $fex_presence = defined($result->{$oid_cucsEquipmentFexPresence}->{$oid_cucsEquipmentFexPresence . '.' . $fex_index}) ? 
                                $result->{$oid_cucsEquipmentFexPresence}->{$oid_cucsEquipmentFexPresence . '.' . $fex_index} : 0;
        
        next if ($self->absent_problem(section => 'fex', instance => $fex_dn));
        next if ($self->check_exclude(section => 'fex', instance => $fex_dn));

        my $exit = $self->get_severity(section => 'fex', threshold => 'presence', value => $fex_presence);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fabric extender '%s' presence is: '%s'",
                                                             $fex_dn, ${$thresholds->{presence}->{$fex_presence}}[0])
                                        );
            next;
        }
        
        $self->{components}->{fex}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Fabric extender '%s' state is '%s' [presence: %s].",
                                                        $fex_dn, ${$thresholds->{operability}->{$fex_operstate}}[0],
                                                        ${$thresholds->{presence}->{$fex_presence}}[0]
                                    ));
        $exit = $self->get_severity(section => 'fex', threshold => 'operability', value => $fex_operstate);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fabric extender '%s' state is '%s'.",
                                                             $fex_dn, ${$thresholds->{operability}->{$fex_operstate}}[0]
                                                             )
                                        );
        }
    }
}

1;
