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

package hardware::server::dell::idrac::snmp::mode::components::pci;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status %map_state);

my $mapping = {
    pCIDeviceStateSettings      => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.80.1.4', map => \%map_state },
    pCIDeviceStatus             => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.80.1.5', map => \%map_status },
    pCIDeviceDescriptionName    => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.80.1.9' }
};
my $oid_pCIDeviceTableEntry = '.1.3.6.1.4.1.674.10892.5.4.1100.80.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_pCIDeviceTableEntry,
        start => $mapping->{pCIDeviceStateSettings}->{oid},
        end => $mapping->{pCIDeviceDescriptionName}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking pci");
    $self->{components}->{pci} = { name => 'pci', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'pci'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_pCIDeviceTableEntry}})) {
        next if ($oid !~ /^$mapping->{pCIDeviceStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_pCIDeviceTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'pci', instance => $instance));
        $self->{components}->{pci}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "pci '%s' status is '%s' [instance = %s] [state = %s]",
                $result->{pCIDeviceDescriptionName}, $result->{pCIDeviceStatus}, $instance, 
                $result->{pCIDeviceStateSettings}
            )
        );

        my $exit = $self->get_severity(label => 'default.state', section => 'pci.state', value => $result->{pCIDeviceStateSettings});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("PCI '%s' state is '%s'", $result->{pCIDeviceDescriptionName}, $result->{pCIDeviceStateSettings})
            );
            next;
        }

        $exit = $self->get_severity(label => 'default.status', section => 'pci.status', value => $result->{pCIDeviceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("PCI '%s' status is '%s'", $result->{pCIDeviceDescriptionName}, $result->{pCIDeviceStatus})
            );
        }
    }
}

1;
