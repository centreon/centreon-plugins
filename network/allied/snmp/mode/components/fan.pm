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

package network::allied::snmp::mode::components::fan;

use strict;
use warnings;

my $map_status = {
    1 => 'failed', 2 => 'good',
};

my $mapping = {
    atEnvMonv2FanDescription    => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.1.1.4' },
    atEnvMonv2FanCurrentSpeed   => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.1.1.5' },
    atEnvMonv2FanLowerThreshold => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.1.1.6' },
    atEnvMonv2FanStatus         => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.1.1.7', map => $map_status },
};
my $oid_atEnvMonv2FanEntry = '.1.3.6.1.4.1.207.8.4.4.3.12.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_atEnvMonv2FanEntry, start => $mapping->{atEnvMonv2FanDescription}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "checking fans");
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_atEnvMonv2FanEntry}})) {
        next if ($oid !~ /^$mapping->{atEnvMonv2FanStatus}->{oid}\.(\d+)\.(\d+)\.(\d+)$/);
        my ($stack_id, $board_index, $fan_index) = ($1, $2, $3);
        my $instance = $stack_id . '.' . $board_index . '.' . $fan_index; 
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_atEnvMonv2FanEntry}, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is %s [instance: %s, speed: %s, stack: %s, board: %s]",
                $result->{atEnvMonv2FanDescription}, 
                $result->{atEnvMonv2FanStatus},
                $instance,
                $result->{atEnvMonv2FanCurrentSpeed},
                $stack_id,
                $board_index
            )
        );
        my $exit = $self->get_severity(section => 'fan', value => $result->{atEnvMonv2FanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "fan '%s' status is %s",
                    $result->{atEnvMonv2FanDescription},
                    $result->{atEnvMonv2FanStatus}
                )
            );
        }

        next if (!defined($result->{atEnvMonv2FanCurrentSpeed}));

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{atEnvMonv2FanCurrentSpeed});
        if ($checked == 0) {
            my $warn_th = '';
            my $crit_th = $result->{atEnvMonv2FanLowerThreshold} . ':';
            $self->{perfdata}->threshold_validate(label => 'warning-fan-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-fan-instance-' . $instance, value => $crit_th);

            $exit = $self->{perfdata}->threshold_check(
                value => $result->{atEnvMonv2FanCurrentSpeed},
                threshold => [ 
                    { label => 'critical-fan-instance-' . $instance, exit_litteral => 'critical' },
                    { label => 'warning-fan-instance-' . $instance, exit_litteral => 'warning' }
                ]
            );
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-fan-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-fan-instance-' . $instance)
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "fan '%s' speed is %s rpm",
                    $result->{atEnvMonv2FanDescription},
                    $result->{atEnvMonv2FanCurrentSpeed}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.fan.speed.rpm', unit => 'rpm',
            instances => ['stack=' . $stack_id, 'board=' . $board_index, 'description=' . $result->{atEnvMonv2FanDescription}],
            value => $result->{atEnvMonv2FanCurrentSpeed},
            warning => $warn,
            critical => $crit, min => 0
        );
    }
}

1;
