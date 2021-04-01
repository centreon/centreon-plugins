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

package hardware::server::dell::idrac::snmp::mode::components::slot;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status);

my $mapping = {
    systemSlotStatus                => { oid => '.1.3.6.1.4.1.674.10892.5.4.1200.10.1.5', map => \%map_status },
    systemSlotSlotExternalSlotName  => { oid => '.1.3.6.1.4.1.674.10892.5.4.1200.10.1.8' }
};
my $oid_systemSlotTableEntry = '.1.3.6.1.4.1.674.10892.5.4.1200.10.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_systemSlotTableEntry,
        start => $mapping->{systemSlotStatus}->{oid},
        end => $mapping->{systemSlotSlotExternalSlotName}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking slots");
    $self->{components}->{slot} = { name => 'slots', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'slot'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_systemSlotTableEntry}})) {
        next if ($oid !~ /^$mapping->{systemSlotStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_systemSlotTableEntry}, instance => $instance);

        next if ($self->check_filter(section => 'slot', instance => $instance));
        $self->{components}->{slot}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "slot '%s' status is '%s' [instance = %s]",
                $result->{systemSlotSlotExternalSlotName}, $result->{systemSlotStatus}, $instance, 
            )
        );

        my $exit = $self->get_severity(label => 'default.status', section => 'slot.status', value => $result->{systemSlotStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Slot '%s' status is '%s'", $result->{systemSlotSlotExternalSlotName}, $result->{systemSlotStatus})
            );
        }
    }
}

1;
