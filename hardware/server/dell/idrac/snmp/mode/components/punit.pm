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

package hardware::server::dell::idrac::snmp::mode::components::punit;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status %map_state);

my $mapping = {
    powerUnitStateSettings  => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.10.1.4', map => \%map_state },
    powerUnitName           => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.10.1.7' },
    powerUnitStatus         => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.10.1.8', map => \%map_status }
};
my $oid_powerUnitTableEntry = '.1.3.6.1.4.1.674.10892.5.4.600.10.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_powerUnitTableEntry,
        start => $mapping->{powerUnitStateSettings}->{oid},
        end => $mapping->{powerUnitStatus}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power units");
    $self->{components}->{punit} = { name => 'power units', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'punit'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_powerUnitTableEntry}})) {
        next if ($oid !~ /^$mapping->{powerUnitStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_powerUnitTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'punit', instance => $instance));
        $self->{components}->{punit}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "power unit '%s' status is '%s' [instance = %s] [state = %s]",
                $result->{powerUnitName}, $result->{powerUnitStatus}, $instance, 
                $result->{powerUnitStateSettings}
            )
        );

        my $exit = $self->get_severity(label => 'default.state', section => 'punit.state', value => $result->{powerUnitStateSettings});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Power unit '%s' state is '%s'", $result->{powerUnitName}, $result->{powerUnitStateSettings})
            );
            next;
        }

        $exit = $self->get_severity(label => 'default.status', section => 'punit.status', value => $result->{powerUnitStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Power unit '%s' status is '%s'", $result->{powerUnitName}, $result->{powerUnitStatus})
            );
        }
    }
}

1;
