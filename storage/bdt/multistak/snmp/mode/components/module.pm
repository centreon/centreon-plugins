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

package storage::bdt::multistak::snmp::mode::components::module;

use strict;
use warnings;

my $mapping = {
    physical_id   => { oid => '.1.3.6.1.4.1.20884.2.4.1.2' }, # bdtDeviceStatModEntryIDPhys
    module_status => { oid => '.1.3.6.1.4.1.20884.2.4.1.4' }, # bdtDeviceStatModEntryDPwr1
    board_status  => { oid => '.1.3.6.1.4.1.20884.2.4.1.5' }, # bdtDeviceStatModEntryDPwr2
    psu_status    => { oid => '.1.3.6.1.4.1.20884.2.4.1.6' }  # bdtDeviceStatModEntryPwrSupply
};
my $oid_module_entry = '.1.3.6.1.4.1.20884.2.4.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_module_entry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking modules');
    $self->{components}->{module} = { name => 'modules', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'module'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $oid_module_entry }})) {
        next if ($oid !~ /^$mapping->{physical_id}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $oid_module_entry }, instance => $instance);

        next if ($self->check_filter(section => 'module', instance => $result->{physical_id}));
        $self->{components}->{module}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "module '%s' status is '%s' [board status: %s] [power supply: %s][instance: %s].",
                $result->{physical_id},
                $result->{module_status},
                $result->{board_status},
                $result->{psu_status},
                $result->{physical_id}
            )
        );
        my $exit = $self->get_severity(label => 'status', section => 'module', instance => $result->{physical_id}, value => $result->{module_status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Module '%s' status is '%s'",
                    $instance, $result->{module_status}
                )
            );
        }

        $exit = $self->get_severity(label => 'status', section => 'module.board', instance => $result->{physical_id}, value => $result->{board_status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Module '%s' board status is '%s'",
                    $instance, $result->{board_status}
                )
            );
        }

        $exit = $self->get_severity(label => 'status', section => 'module.psu', instance => $result->{physical_id}, value => $result->{psu_status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Module '%s' power supply status is '%s'",
                    $instance, $result->{psu_status}
                )
            );
        }
    }
}

1;
