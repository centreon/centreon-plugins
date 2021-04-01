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

package hardware::server::dell::idrac::snmp::mode::components::memory;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status %map_state);

my $mapping = {
    memoryDeviceStateSettings  => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.50.1.4', map => \%map_state },
    memoryDeviceStatus         => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.50.1.5', map => \%map_status },
    memoryDeviceLocationName   => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.50.1.8' }
};
my $oid_memoryDeviceTableEntry = '.1.3.6.1.4.1.674.10892.5.4.1100.50.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_memoryDeviceTableEntry,
        start => $mapping->{memoryDeviceStateSettings}->{oid},
        end => $mapping->{memoryDeviceLocationName}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking memories");
    $self->{components}->{memory} = {name => 'memories', total => 0, skip => 0};
    return if ($self->check_filter(section => 'memory'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_memoryDeviceTableEntry}})) {
        next if ($oid !~ /^$mapping->{memoryDeviceStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_memoryDeviceTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'memory', instance => $instance));
        $self->{components}->{memory}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "memory '%s' status is '%s' [instance = %s] [state = %s]",
                $result->{memoryDeviceLocationName}, $result->{memoryDeviceStatus}, $instance, 
                $result->{memoryDeviceStateSettings}
            )
        );

        my $exit = $self->get_severity(label => 'default.state', section => 'memory.state', value => $result->{memoryDeviceStateSettings});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Memory '%s' state is '%s'", $result->{memoryDeviceLocationName}, $result->{memoryDeviceStateSettings})
            );
            next;
        }

        $exit = $self->get_severity(label => 'default.status', section => 'memory.status', value => $result->{memoryDeviceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Memory '%s' status is '%s'", $result->{memoryDeviceLocationName}, $result->{memoryDeviceStatus})
            );
        }
    }
}

1;
