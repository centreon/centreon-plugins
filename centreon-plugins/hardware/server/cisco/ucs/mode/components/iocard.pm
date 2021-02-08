#
# Copyright 2021 Centreon (http://www.centreon.com/)
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
use hardware::server::cisco::ucs::mode::components::resources qw(%mapping_presence %mapping_operability);

# In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
my $mapping1 = {
    cucsEquipmentIOCardPresence => { oid => '.1.3.6.1.4.1.9.9.719.1.15.30.1.31', map => \%mapping_presence },
};
my $mapping2 = {
    cucsEquipmentIOCardOperState => { oid => '.1.3.6.1.4.1.9.9.719.1.15.30.1.25', map => \%mapping_operability },
};
my $oid_cucsEquipmentIOCardDn = '.1.3.6.1.4.1.9.9.719.1.15.30.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping1->{cucsEquipmentIOCardPresence}->{oid} },
        { oid => $mapping2->{cucsEquipmentIOCardOperState}->{oid} }, { oid => $oid_cucsEquipmentIOCardDn };
}

sub check {
    my ($self) = @_;

    # In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
    $self->{output}->output_add(long_msg => "Checking io cards");
    $self->{components}->{iocard} = {name => 'io cards', total => 0, skip => 0};
    return if ($self->check_filter(section => 'iocard'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cucsEquipmentIOCardDn}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $iocard_dn = $self->{results}->{$oid_cucsEquipmentIOCardDn}->{$oid};
        my $result = $self->{snmp}->map_instance(mapping => $mapping1, results => $self->{results}->{$mapping1->{cucsEquipmentIOCardPresence}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{cucsEquipmentIOCardOperState}->{oid}}, instance => $instance);
        
        next if ($self->absent_problem(section => 'iocard', instance => $iocard_dn));
        next if ($self->check_filter(section => 'iocard', instance => $iocard_dn));

        $self->{output}->output_add(
            long_msg => sprintf(
                "IO cards '%s' state is '%s' [presence: %s].",
                $iocard_dn, $result2->{cucsEquipmentIOCardOperState},
                $result->{cucsEquipmentIOCardPresence}
            )
        );
        
        my $exit = $self->get_severity(section => 'iocard.presence', label => 'default.presence', value => $result->{cucsEquipmentIOCardPresence});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "IO cards '%s' presence is: '%s'",
                    $iocard_dn, $result->{cucsEquipmentIOCardPresence}
                )
            );
            next;
        }

        $self->{components}->{iocard}->{total}++;
        
        $exit = $self->get_severity(section => 'iocard.operability', label => 'default.operability', value => $result2->{cucsEquipmentIOCardOperState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "IO cards '%s' state is '%s'.",
                    $iocard_dn, $result2->{cucsEquipmentIOCardOperState}
                )
            );
        }
    }
}

1;
