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

package hardware::server::dell::idrac::snmp::mode::components::processor;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status %map_state);

my $mapping = {
    processorDeviceStatusStateSettings  => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.32.1.4', map => \%map_state },
    processorDeviceStatusStatus         => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.32.1.5', map => \%map_status },
    processorDeviceStatusLocationName   => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.32.1.7' },
};
my $oid_processorDeviceStatusTableEntry = '.1.3.6.1.4.1.674.10892.5.4.1100.32.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_processorDeviceStatusTableEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking processors");
    $self->{components}->{processor} = {name => 'processors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'processor'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_processorDeviceStatusTableEntry}})) {
        next if ($oid !~ /^$mapping->{processorDeviceStatusStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_processorDeviceStatusTableEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'processor', instance => $instance));
        $self->{components}->{processor}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("processor '%s' status is '%s' [instance = %s] [state = %s]",
                                    $result->{processorDeviceStatusLocationName}, $result->{processorDeviceStatusStatus}, $instance, 
                                    $result->{processorDeviceStatusStateSettings}));
        
        my $exit = $self->get_severity(label => 'default.state', section => 'processor.state', value => $result->{processorDeviceStatusStateSettings});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Processor '%s' state is '%s'", $result->{processorDeviceStatusLocationName}, $result->{processorDeviceStatusStateSettings}));
            next;
        }

        $exit = $self->get_severity(label => 'default.status', section => 'processor.status', value => $result->{processorDeviceStatusStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Processor '%s' status is '%s'", $result->{processorDeviceStatusLocationName}, $result->{processorDeviceStatusStatus}));
        }
    }
}

1;