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

package hardware::server::cisco::ucs::mode::components::blade;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw(%mapping_presence %mapping_overall_status);

# In MIB 'CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB'
my $mapping1 = {
    cucsComputeBladePresence => { oid => '.1.3.6.1.4.1.9.9.719.1.9.2.1.45', map => \%mapping_presence },
};
my $mapping2 = {
    cucsComputeBladeOperState => { oid => '.1.3.6.1.4.1.9.9.719.1.9.2.1.42', map => \%mapping_overall_status },
};
my $oid_cucsComputeBladeDn = '.1.3.6.1.4.1.9.9.719.1.9.2.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping1->{cucsComputeBladePresence}->{oid} },
        { oid => $mapping2->{cucsComputeBladeOperState}->{oid} }, { oid => $oid_cucsComputeBladeDn };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking blades");
    $self->{components}->{blade} = {name => 'blades', total => 0, skip => 0};
    return if ($self->check_filter(section => 'blade'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cucsComputeBladeDn}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $blade_dn = $self->{results}->{$oid_cucsComputeBladeDn}->{$oid};
        my $result = $self->{snmp}->map_instance(mapping => $mapping1, results => $self->{results}->{$mapping1->{cucsComputeBladePresence}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{cucsComputeBladeOperState}->{oid}}, instance => $instance);

        next if ($self->absent_problem(section => 'blade', instance => $blade_dn));
        next if ($self->check_filter(section => 'blade', instance => $blade_dn));

        $self->{output}->output_add(
            long_msg => sprintf(
                "blade '%s' state is '%s' [presence: %s].",
                $blade_dn, $result2->{cucsComputeBladeOperState},
                $result->{cucsComputeBladePresence}
            )
        );
        
        my $exit = $self->get_severity(section => 'blade.presence', label => 'default.presence', value => $result->{cucsComputeBladePresence});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "blade '%s' presence is: '%s'",
                    $blade_dn, $result->{cucsComputeBladePresence}
                )
            );
            next;
        }
        
        $self->{components}->{blade}->{total}++;

        $exit = $self->get_severity(section => 'blade.overall_status', label => 'default.overall_status', value => $result2->{cucsComputeBladeOperState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "blade '%s' state is '%s'",
                    $blade_dn, $result2->{cucsComputeBladeOperState}
                )
            );
        }
    }
}

1;
