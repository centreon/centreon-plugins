#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package hardware::server::dell::idrac::snmp::mode::components::pdisk;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status %map_pdisk_state);

my $mapping = {
    physicalDiskState           => { oid => '.1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.4', map => \%map_pdisk_state },
    physicalDiskComponentStatus => { oid => '.1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.24', map => \%map_status },
    physicalDiskFQDD            => { oid => '.1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.54' },
};
my $oid_physicalDiskTableEntry = '.1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_physicalDiskTableEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking physical disks");
    $self->{components}->{pdisk} = {name => 'physical disks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'pdisk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_physicalDiskTableEntry}})) {
        next if ($oid !~ /^$mapping->{physicalDiskComponentStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_physicalDiskTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'pdisk', instance => $instance));
        $self->{components}->{pdisk}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("power unit '%s' status is '%s' [instance = %s] [state = %s]",
                                    $result->{physicalDiskFQDD}, $result->{physicalDiskComponentStatus}, $instance, 
                                    $result->{physicalDiskState}));
        
        my $exit = $self->get_severity(section => 'pdisk.state', value => $result->{physicalDiskState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power unit '%s' state is '%s'", $result->{physicalDiskFQDD}, $result->{physicalDiskState}));
            next;
        }

        $exit = $self->get_severity(label => 'default.status', section => 'pdisk.status', value => $result->{physicalDiskComponentStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power unit '%s' status is '%s'", $result->{physicalDiskFQDD}, $result->{physicalDiskComponentStatus}));
        }
    }
}

1;