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

package network::allied::snmp::mode::components::voltage;

use strict;
use warnings;

my $map_status = {
    1 => 'outOfRange', 2 => 'inRange',
};

my $mapping = {
    atEnvMonv2VoltageDescription    => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.2.1.4' },
    atEnvMonv2VoltageCurrent        => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.2.1.5' },
    atEnvMonv2VoltageUpperThreshold => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.2.1.6' },
    atEnvMonv2VoltageLowerThreshold => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.2.1.7' },
    atEnvMonv2VoltageStatus         => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.2.1.8', map => $map_status },
};
my $oid_atEnvMonv2VoltageEntry = '.1.3.6.1.4.1.207.8.4.4.3.12.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_atEnvMonv2VoltageEntry, start => $mapping->{atEnvMonv2VoltageDescription}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "checking voltages");
    $self->{components}->{voltage} = { name => 'voltages', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'voltage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_atEnvMonv2VoltageEntry}})) {
        next if ($oid !~ /^$mapping->{atEnvMonv2VoltageStatus}->{oid}\.(\d+)\.(\d+)\.(\d+)$/);
        my ($stack_id, $board_index, $voltage_index) = ($1, $2, $3);
        my $instance = $stack_id . '.' . $board_index . '.' . $voltage_index; 
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_atEnvMonv2VoltageEntry}, instance => $instance);

        next if ($self->check_filter(section => 'voltage', instance => $instance));
        $self->{components}->{voltage}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "voltage '%s' status is %s [instance: %s, value: %s mV, stack: %s, board: %s]",
                $result->{atEnvMonv2VoltageDescription}, 
                $result->{atEnvMonv2VoltageStatus},
                $instance,
                $result->{atEnvMonv2VoltageCurrent},
                $stack_id,
                $board_index
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'voltage', value => $result->{atEnvMonv2VoltageStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "voltage '%s' status is %s",
                    $result->{atEnvMonv2VoltageDescription},
                    $result->{atEnvMonv2VoltageStatus}
                )
            );
        }

        next if (!defined($result->{atEnvMonv2VoltageCurrent}));

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{atEnvMonv2VoltageCurrent});
        if ($checked == 0) {
            my $warn_th = '';
            my $crit_th = $result->{atEnvMonv2VoltageLowerThreshold} . ':' . $result->{atEnvMonv2VoltageUpperThreshold};
            $self->{perfdata}->threshold_validate(label => 'warning-voltage-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-voltage-instance-' . $instance, value => $crit_th);

            $exit = $self->{perfdata}->threshold_check(
                value => $result->{atEnvMonv2VoltageCurrent},
                threshold => [ 
                    { label => 'critical-voltage-instance-' . $instance, exit_litteral => 'critical' },
                    { label => 'warning-voltage-instance-' . $instance, exit_litteral => 'warning' }
                ]
            );
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-voltage-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-voltage-instance-' . $instance)
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "voltage '%s' is %s mv",
                    $result->{atEnvMonv2VoltageDescription},
                    $result->{atEnvMonv2VoltageCurrent}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.voltage.millivolt', unit => 'mV',
            instances => ['stack=' . $stack_id, 'board=' . $board_index, 'index=' . $voltage_index, 'description=' . $result->{atEnvMonv2VoltageDescription}],
            value => $result->{atEnvMonv2VoltageCurrent},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
