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

package hardware::server::cisco::ucs::mode::components::psu;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw(%mapping_presence %mapping_operability);

# In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
my $mapping1 = {
    cucsEquipmentPsuPresence => { oid => '.1.3.6.1.4.1.9.9.719.1.15.56.1.11', map => \%mapping_presence },
};
my $mapping2 = {
    cucsEquipmentPsuOperState => { oid => '.1.3.6.1.4.1.9.9.719.1.15.56.1.7', map => \%mapping_operability },
};
my $oid_cucsEquipmentPsuDn = '.1.3.6.1.4.1.9.9.719.1.15.56.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping1->{cucsEquipmentPsuPresence}->{oid} },
        { oid => $mapping2->{cucsEquipmentPsuOperState}->{oid} }, { oid => $oid_cucsEquipmentPsuDn };
}

sub check {
    my ($self) = @_;

    # In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cucsEquipmentPsuDn}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $psu_dn = $self->{results}->{$oid_cucsEquipmentPsuDn}->{$oid};
        my $result = $self->{snmp}->map_instance(mapping => $mapping1, results => $self->{results}->{$mapping1->{cucsEquipmentPsuPresence}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{cucsEquipmentPsuOperState}->{oid}}, instance => $instance);
        
        next if ($self->absent_problem(section => 'psu', instance => $psu_dn));
        next if ($self->check_filter(section => 'psu', instance => $psu_dn));

        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' state is '%s' [presence: %s].",
                $psu_dn, $result2->{cucsEquipmentPsuOperState},
                $result->{cucsEquipmentPsuPresence}
            )
        );

        my $exit = $self->get_severity(section => 'psu.presence', label => 'default.presence', value => $result->{cucsEquipmentPsuPresence});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "power supply '%s' presence is: '%s'",
                    $psu_dn, $result->{cucsEquipmentPsuPresence}
                )
            );
            next;
        }

        $self->{components}->{psu}->{total}++;
        
        $exit = $self->get_severity(section => 'psu.operability', label => 'default.operability', value => $result2->{cucsEquipmentPsuOperState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "power supply '%s' state is '%s'.",
                    $psu_dn, $result2->{cucsEquipmentPsuOperState}
                )
            );
        }
    }
}

1;
