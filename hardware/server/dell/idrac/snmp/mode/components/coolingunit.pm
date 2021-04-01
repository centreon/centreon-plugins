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

package hardware::server::dell::idrac::snmp::mode::components::coolingunit;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status %map_state);

my $mapping = {
    coolingUnitStateSettings  => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.10.1.4', map => \%map_state },
    coolingUnitName           => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.10.1.7' },
    coolingUnitStatus         => { oid => '.1.3.6.1.4.1.674.10892.5.4.700.10.1.8', map => \%map_status }
};
my $oid_coolingUnitTableEntry = '.1.3.6.1.4.1.674.10892.5.4.700.10.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_coolingUnitTableEntry,
        start => $mapping->{coolingUnitStateSettings}->{oid},
        end => $mapping->{coolingUnitStatus}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cooling units");
    $self->{components}->{coolingunit} = {name => 'cooling units', total => 0, skip => 0};
    return if ($self->check_filter(section => 'coolingunit'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_coolingUnitTableEntry}})) {
        next if ($oid !~ /^$mapping->{coolingUnitStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_coolingUnitTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'coolingunit', instance => $instance));
        $self->{components}->{coolingunit}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "cooling unit '%s' status is '%s' [instance = %s] [state = %s]",
                $result->{coolingUnitName}, $result->{coolingUnitStatus}, $instance, 
                $result->{coolingUnitStateSettings}
            )
        );

        my $exit = $self->get_severity(label => 'default.state', section => 'coolingunit.state', value => $result->{coolingUnitStateSettings});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Cooling unit '%s' state is '%s'", $result->{coolingUnitName}, $result->{coolingUnitStateSettings})
            );
            next;
        }

        $exit = $self->get_severity(label => 'default.status', section => 'coolingunit.status', value => $result->{coolingUnitStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Cooling unit '%s' status is '%s'", $result->{coolingUnitName}, $result->{coolingUnitStatus})
            );
        }
    }
}

1;
