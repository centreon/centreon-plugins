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

package hardware::server::cisco::ucs::mode::components::fex;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw(%mapping_presence %mapping_operability);

# In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
my $mapping1 = {
    cucsEquipmentFexPresence => { oid => '.1.3.6.1.4.1.9.9.719.1.15.19.1.24', map => \%mapping_presence },
};
my $mapping2 = {
    cucsEquipmentFexOperState => { oid => '.1.3.6.1.4.1.9.9.719.1.15.19.1.21', map => \%mapping_operability },
};
my $oid_cucsEquipmentFexDn = '.1.3.6.1.4.1.9.9.719.1.15.19.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping1->{cucsEquipmentFexPresence}->{oid} },
        { oid => $mapping2->{cucsEquipmentFexOperState}->{oid} }, { oid => $oid_cucsEquipmentFexDn };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fabric extenders");
    $self->{components}->{fex} = {name => 'fabric extenders', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fex'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cucsEquipmentFexDn}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $fex_dn = $self->{results}->{$oid_cucsEquipmentFexDn}->{$oid};
        my $result = $self->{snmp}->map_instance(mapping => $mapping1, results => $self->{results}->{$mapping1->{cucsEquipmentFexPresence}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{cucsEquipmentFexOperState}->{oid}}, instance => $instance);
        
        next if ($self->absent_problem(section => 'fex', instance => $fex_dn));
        next if ($self->check_filter(section => 'fex', instance => $fex_dn));

        $self->{output}->output_add(
            long_msg => sprintf(
                "Fabric extender '%s' state is '%s' [presence: %s].",
                $fex_dn, $result2->{cucsEquipmentFexOperState},
                $result->{cucsEquipmentFexPresence}
            )
        );
        
        my $exit = $self->get_severity(section => 'fex.presence', label => 'default.presence', value => $result->{cucsEquipmentFexPresence});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Fabric extender '%s' presence is: '%s'",
                    $fex_dn, $result->{cucsEquipmentFexPresence}
                )
            );
            next;
        }

        $self->{components}->{fex}->{total}++;

        $exit = $self->get_severity(section => 'fex.presence', label => 'default.operability', value => $result2->{cucsEquipmentFexOperState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Fabric extender '%s' state is '%s'.",
                    $fex_dn, $result2->{cucsEquipmentFexOperState}
                )
            );
        }
    }
}

1;
