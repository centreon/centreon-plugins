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

package network::allied::snmp::mode::components::temperature;

use strict;
use warnings;

my $map_status = {
    1 => 'outOfRange', 2 => 'inRange',
};

my $mapping = {
    atEnvMonv2TemperatureDescription    => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.3.1.4' },
    atEnvMonv2TemperatureCurrent        => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.3.1.5' },
    atEnvMonv2TemperatureUpperThreshold => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.3.1.6' },
    atEnvMonv2TemperatureStatus         => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.3.1.7', map => $map_status },
};
my $oid_atEnvMonv2TemperatureEntry = '.1.3.6.1.4.1.207.8.4.4.3.12.3.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_atEnvMonv2TemperatureEntry, start => $mapping->{atEnvMonv2TemperatureDescription}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_atEnvMonv2TemperatureEntry}})) {
        next if ($oid !~ /^$mapping->{atEnvMonv2TemperatureStatus}->{oid}\.(\d+)\.(\d+)\.(\d+)$/);
        my ($stack_id, $board_index, $temp_index) = ($1, $2, $3);
        my $instance = $stack_id . '.' . $board_index . '.' . $temp_index; 
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_atEnvMonv2TemperatureEntry}, instance => $instance);

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' status is %s [instance: %s, speed: %s, stack: %s, board: %s]",
                $result->{atEnvMonv2TemperatureDescription}, 
                $result->{atEnvMonv2TemperatureStatus},
                $instance,
                $result->{atEnvMonv2TemperatureCurrent},
                $stack_id,
                $board_index
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{atEnvMonv2TemperatureStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "temperature '%s' status is %s",
                    $result->{atEnvMonv2TemperatureDescription},
                    $result->{atEnvMonv2TemperatureStatus}
                )
            );
        }

        next if (!defined($result->{atEnvMonv2TemperatureCurrent}));

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{atEnvMonv2TemperatureCurrent});
        if ($checked == 0) {
            my $warn_th = '';
            my $crit_th = ':' . $result->{atEnvMonv2TemperatureUpperThreshold};
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);

            $exit = $self->{perfdata}->threshold_check(
                value => $result->{atEnvMonv2TemperatureCurrent},
                threshold => [ 
                    { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' },
                    { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' }
                ]
            );
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance)
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "temperture '%s' is %s C",
                    $result->{atEnvMonv2TemperatureDescription},
                    $result->{atEnvMonv2TemperatureCurrent}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.celsius', unit => 'C',
            instances => ['stack=' . $stack_id, 'board=' . $board_index, 'description=' . $result->{atEnvMonv2TemperatureDescription}],
            value => $result->{atEnvMonv2TemperatureCurrent},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
