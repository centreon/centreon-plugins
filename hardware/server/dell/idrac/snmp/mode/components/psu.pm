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

package hardware::server::dell::idrac::snmp::mode::components::psu;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status);

my $mapping = {
    powerSupplyStatus       => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.12.1.5', map => \%map_status },
    powerSupplyLocationName => { oid => '.1.3.6.1.4.1.674.10892.5.4.600.12.1.8' }
};
my $oid_powerSupplyTableEntry = '.1.3.6.1.4.1.674.10892.5.4.600.12.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, {
        oid => $oid_powerSupplyTableEntry,
        start => $mapping->{powerSupplyStatus}->{oid},
        end => $mapping->{powerSupplyLocationName}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = { name => 'power supplies', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_powerSupplyTableEntry}})) {
        next if ($oid !~ /^$mapping->{powerSupplyStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_powerSupplyTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' status is '%s' [instance = %s]",
                $result->{powerSupplyLocationName}, $result->{powerSupplyStatus}, $instance, 
            )
        );

        my $exit = $self->get_severity(label => 'default.status', section => 'psu.status', value => $result->{powerSupplyStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Power supply '%s' status is '%s'",
                    $result->{powerSupplyLocationName},
                    $result->{powerSupplyStatus}
                )
            );
        }
    }
}

1;
