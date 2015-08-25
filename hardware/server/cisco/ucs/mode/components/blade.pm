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

package hardware::server::cisco::ucs::mode::components::blade;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw($thresholds);

sub check {
    my ($self) = @_;

    # In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
    $self->{output}->output_add(long_msg => "Checking blades");
    $self->{components}->{blade} = {name => 'blades', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'blade'));
    
    my $oid_cucsComputeBladePresence = '.1.3.6.1.4.1.9.9.719.1.9.2.1.45';
    my $oid_cucsComputeBladeOperState = '.1.3.6.1.4.1.9.9.719.1.9.2.1.42';
    my $oid_cucsComputeBladeDn = '.1.3.6.1.4.1.9.9.719.1.9.2.1.2';

    my $result = $self->{snmp}->get_multiple_table(oids => [ 
                                                            { oid => $oid_cucsComputeBladePresence },
                                                            { oid => $oid_cucsComputeBladeOperState },
                                                            { oid => $oid_cucsComputeBladeDn },
                                                            ]
                                                   );
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_cucsComputeBladePresence}})) {
        # index
        $key =~ /\.(\d+)$/;
        my $blade_index = $1;        
        my $blade_dn = $result->{$oid_cucsComputeBladeDn}->{$oid_cucsComputeBladeDn . '.' . $blade_index};
        my $blade_operstate = defined($result->{$oid_cucsComputeBladeOperState}->{$oid_cucsComputeBladeOperState . '.' . $blade_index}) ?
                                $result->{$oid_cucsComputeBladeOperState}->{$oid_cucsComputeBladeOperState . '.' . $blade_index} : 0; # unknown
        my $blade_presence = defined($result->{$oid_cucsComputeBladePresence}->{$oid_cucsComputeBladePresence . '.' . $blade_index}) ? 
                                $result->{$oid_cucsComputeBladePresence}->{$oid_cucsComputeBladePresence . '.' . $blade_index} : 0;
        
        next if ($self->absent_problem(section => 'blade', instance => $blade_dn));
        next if ($self->check_exclude(section => 'blade', instance => $blade_dn));

        my $exit = $self->get_severity(section => 'blade', threshold => 'presence', value => $blade_presence);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("blade '%s' presence is: '%s'",
                                                             $blade_dn, ${$thresholds->{presence}{$blade_presence}}[0])
                                        );
            next;
        }
        
        $self->{components}->{blade}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("blade '%s' state is '%s' [presence: %s].",
                                                        $blade_dn, ${$thresholds->{overall_status}->{$blade_operstate}}[0],
                                                        ${$thresholds->{presence}->{$blade_presence}}[0]
                                    ));
        $exit = $self->get_severity(section => 'blade', threshold => 'overall_status', value => $blade_operstate);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("blade '%s' state is '%s'.",
                                                             $blade_dn, ${$thresholds->{overall_status}->{$blade_operstate}}[0]
                                                             )
                                        );
        }
    }
}

1;
