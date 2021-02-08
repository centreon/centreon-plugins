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

package hardware::server::cisco::ucs::mode::components::fan;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw(%mapping_presence %mapping_operability);

# In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
my $mapping1 = {
    cucsEquipmentFanPresence => { oid => '.1.3.6.1.4.1.9.9.719.1.15.12.1.13', map => \%mapping_presence },
};
my $mapping2 = {
    cucsEquipmentFanOperState => { oid => '.1.3.6.1.4.1.9.9.719.1.15.12.1.9', map => \%mapping_operability },
};
my $oid_cucsEquipmentFanDn = '.1.3.6.1.4.1.9.9.719.1.15.12.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping1->{cucsEquipmentFanPresence}->{oid} },
        { oid => $mapping2->{cucsEquipmentFanOperState}->{oid} }, { oid => $oid_cucsEquipmentFanDn };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cucsEquipmentFanDn}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $fan_dn = $self->{results}->{$oid_cucsEquipmentFanDn}->{$oid};
        my $result = $self->{snmp}->map_instance(mapping => $mapping1, results => $self->{results}->{$mapping1->{cucsEquipmentFanPresence}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{cucsEquipmentFanOperState}->{oid}}, instance => $instance);
        
        next if ($self->absent_problem(section => 'fan', instance => $fan_dn));
        next if ($self->check_filter(section => 'fan', instance => $fan_dn));

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' state is '%s' [presence: %s].",
                $fan_dn, $result2->{cucsEquipmentFanOperState},
                $result->{cucsEquipmentFanPresence}
            )
        );

        my $exit = $self->get_severity(section => 'fan.presence', label => 'default.presence', value => $result->{cucsEquipmentFanPresence});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "fan '%s' presence is: '%s'",
                    $fan_dn, $result->{cucsEquipmentFanPresence}
                )
            );
            next;
        }
        
        $self->{components}->{fan}->{total}++;

        $exit = $self->get_severity(section => 'fan.operability', label => 'default.operability', value => $result2->{cucsEquipmentFanOperState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "fan '%s' state is '%s'",
                    $fan_dn, $result2->{cucsEquipmentFanOperState}
                )
            );
        }
    }
}

1;
