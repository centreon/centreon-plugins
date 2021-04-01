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

package hardware::server::dell::idrac::snmp::mode::components::processor;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status %map_state);

my $mapping = {
    processorDeviceStateSettings  => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.30.1.4', map => \%map_state },
    processorDeviceStatus         => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.30.1.5', map => \%map_status },
    processorDeviceFQDD           => { oid => '.1.3.6.1.4.1.674.10892.5.4.1100.30.1.26' }
};
my $oid_processorDeviceTableEntry = '.1.3.6.1.4.1.674.10892.5.4.1100.30.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}},
        { oid => $oid_processorDeviceTableEntry, start => $mapping->{processorDeviceStateSettings}->{oid}, end => $mapping->{processorDeviceStatus}->{oid} },
        { oid => $mapping->{processorDeviceFQDD}->{oid} }
        ;
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking processors");
    $self->{components}->{processor} = { name => 'processors', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'processor'));

    my $snmp_result = { %{$self->{results}->{ $oid_processorDeviceTableEntry }}, %{$self->{results}->{ $mapping->{processorDeviceFQDD}->{oid} }} };
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{processorDeviceStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        next if ($self->check_filter(section => 'processor', instance => $instance));
        $self->{components}->{processor}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "processor '%s' status is '%s' [instance = %s] [state = %s]",
                $result->{processorDeviceFQDD}, $result->{processorDeviceStatus}, $instance, 
                $result->{processorDeviceStateSettings}
            )
        );

        my $exit = $self->get_severity(label => 'default.state', section => 'processor.state', value => $result->{processorDeviceStateSettings});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Processor '%s' state is '%s'", $result->{processorDeviceFQDD}, $result->{processorDeviceStateSettings})
            );
            next;
        }

        $exit = $self->get_severity(label => 'default.status', section => 'processor.status', value => $result->{processorDeviceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Processor '%s' status is '%s'", $result->{processorDeviceFQDD}, $result->{processorDeviceStatus})
            );
        }
    }
}

1;
