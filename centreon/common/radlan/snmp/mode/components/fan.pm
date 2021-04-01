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

package centreon::common::radlan::snmp::mode::components::fan;

use strict;
use warnings;
use centreon::common::radlan::snmp::mode::components::resources qw(
    $rl_envmon_state
    $oid_rlPhdUnitEnvParamMonitorAutoRecoveryEnable
    $oid_rlPhdUnitEnvParamEntry
);

my $mapping_stack = {
    new => {
        rlPhdUnitEnvParamFan1Status => { oid => '.1.3.6.1.4.1.89.53.15.1.4', map => $rl_envmon_state },
        rlPhdUnitEnvParamFan2Status => { oid => '.1.3.6.1.4.1.89.53.15.1.5', map => $rl_envmon_state },
        rlPhdUnitEnvParamFan3Status => { oid => '.1.3.6.1.4.1.89.53.15.1.6', map => $rl_envmon_state },
        rlPhdUnitEnvParamFan4Status => { oid => '.1.3.6.1.4.1.89.53.15.1.7', map => $rl_envmon_state },
        rlPhdUnitEnvParamFan5Status => { oid => '.1.3.6.1.4.1.89.53.15.1.8', map => $rl_envmon_state },
        rlPhdUnitEnvParamFan6Status => { oid => '.1.3.6.1.4.1.89.53.15.1.9', map => $rl_envmon_state }
    },
    old => {
        rlPhdUnitEnvParamFan1Status => { oid => '.1.3.6.1.4.1.89.53.15.1.4', map => $rl_envmon_state },
        rlPhdUnitEnvParamFan2Status => { oid => '.1.3.6.1.4.1.89.53.15.1.5', map => $rl_envmon_state },
        rlPhdUnitEnvParamFan3Status => { oid => '.1.3.6.1.4.1.89.53.15.1.6', map => $rl_envmon_state },
        rlPhdUnitEnvParamFan4Status => { oid => '.1.3.6.1.4.1.89.53.15.1.7', map => $rl_envmon_state },
        rlPhdUnitEnvParamFan5Status => { oid => '.1.3.6.1.4.1.89.53.15.1.8', map => $rl_envmon_state }
    }
};

sub load {
    my ($self) = @_;
}

sub check_fan_stack {
    my ($self) = @_;

    my $num_fans = 5;
    $num_fans = 6 if ($self->{radlan_new} == 1);

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rlPhdUnitEnvParamEntry}})) {
        next if ($oid !~ /^$mapping_stack->{new}->{rlPhdUnitEnvParamFan1Status}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $self->{radlan_new} == 1 ? $mapping_stack->{new} : $mapping_stack->{old},
            results => $self->{results}->{$oid_rlPhdUnitEnvParamEntry},
            instance => $instance
        );

        for (my $i = 1; $i <= $num_fans; $i++) {
            my $instance2 = 'stack.' . $instance . '.fan.' . $i;
            my $name = 'rlPhdUnitEnvParamFan' . $i . 'Status';

            next if ($self->check_filter(section => 'fan', instance => $instance2));
            next if ($result->{$name} =~ /notPresent/i &&
                $self->absent_problem(section => 'fan', instance => $instance2));

            $self->{components}->{fan}->{total}++;
            $self->{output}->output_add(
                long_msg => sprintf(
                    "fan '%s' status is '%s' [instance: %s]",
                    $instance2,
                    $result->{$name},
                    $instance2
                )
            );

            my $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{$name});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Fan '%s' status is '%s'",
                        $instance2,
                        $result->{$name}
                    )
                );
            }
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = { name => 'fan', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    check_fan_stack($self);
}

1;
