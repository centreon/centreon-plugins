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

package hardware::server::cisco::ucs::mode::components::chassis;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw(%mapping_operability);

# In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
# Don't do the 'presence'. Is 'unknown' ??!!!
my $mapping1 = {
    cucsEquipmentChassisOperState => { oid => '.1.3.6.1.4.1.9.9.719.1.15.7.1.27', map => \%mapping_operability },
};
my $oid_cucsEquipmentChassisDn = '.1.3.6.1.4.1.9.9.719.1.15.7.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping1->{cucsEquipmentChassisOperState}->{oid} },
        { oid => $oid_cucsEquipmentChassisDn };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking chassis");
    $self->{components}->{chassis} = {name => 'chassis', total => 0, skip => 0};
    return if ($self->check_filter(section => 'chassis'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cucsEquipmentChassisDn}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $chassis_dn = $self->{results}->{$oid_cucsEquipmentChassisDn}->{$oid};
        my $result = $self->{snmp}->map_instance(mapping => $mapping1, results => $self->{results}->{$mapping1->{cucsEquipmentChassisOperState}->{oid}}, instance => $instance);

        next if ($self->absent_problem(section => 'chassis', instance => $chassis_dn));
        next if ($self->check_filter(section => 'chassis', instance => $chassis_dn));
        
        $self->{components}->{chassis}->{total}++;
        
        $self->{output}->output_add(
            long_msg => sprintf(
                "chassis '%s' state is '%s'.",
                $chassis_dn, $result->{cucsEquipmentChassisOperState}
            )
        );
        my $exit = $self->get_severity(section => 'chassis.operability', label => 'default.operability', value => $result->{cucsEquipmentChassisOperState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "chassis '%s' state is '%s'",
                    $chassis_dn, $result->{cucsEquipmentChassisOperState}
                )
            );
        }
    }
}

1;
