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

package centreon::common::cisco::smallbusiness::snmp::mode::components::psu;

use strict;
use warnings;
use centreon::common::cisco::smallbusiness::snmp::mode::components::resources qw(
    $rl_envmon_state
    $oid_rlPhdUnitEnvParamEntry
);

my $mapping_stack = {
    rlPhdUnitEnvParamMainPSStatus      => { oid => '.1.3.6.1.4.1.9.6.1.101.53.15.1.2', map => $rl_envmon_state },
    rlPhdUnitEnvParamRedundantPSStatus => { oid => '.1.3.6.1.4.1.9.6.1.101.53.15.1.3', map => $rl_envmon_state }
};

my $mapping = {
    rlEnvMonSupplyStatusDescr => { oid => '.1.3.6.1.4.1.9.6.1.101.83.1.2.1.2' },
    rlEnvMonSupplyState => { oid => '.1.3.6.1.4.1.9.6.1.101.83.1.2.1.3', map => $rl_envmon_state }
};
my $oid_rlEnvMonSupplyStatusEntry = '.1.3.6.1.4.1.9.6.1.101.83.1.2.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, {
        oid => $oid_rlEnvMonSupplyStatusEntry,
        $mapping->{rlEnvMonSupplyStatusDescr}->{oid},
        $mapping->{rlEnvMonSupplyState}->{oid}
    };
}

sub check_psu_stack {
    my ($self) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rlPhdUnitEnvParamEntry}})) {
        next if ($oid !~ /^$mapping_stack->{rlPhdUnitEnvParamMainPSStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_stack, results => $self->{results}->{$oid_rlPhdUnitEnvParamEntry}, instance => $instance);

        foreach (['rlPhdUnitEnvParamMainPSStatus', 'main.psu'], ['rlPhdUnitEnvParamRedundantPSStatus', 'redundant.psu']) {
            my $instance2 = 'stack.' . $instance . '.' . $_->[1];
            
            next if ($self->check_filter(section => 'psu', instance => $instance2));
            next if ($result->{$_->[0]} =~ /notPresent/i &&  
                $self->absent_problem(section => 'psu', instance => $instance2));

            $self->{components}->{psu}->{total}++;
            $self->{output}->output_add(
                long_msg => sprintf(
                    "power supply '%s' status is '%s' [instance: %s]",
                    $instance2,
                    $result->{$_->[0]},
                    $instance2
                )
            );

            my $exit = $self->get_severity(label => 'default', section => 'psu', value => $result->{$_->[0]});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Power supply '%s' status is '%s'",
                        $instance2,
                        $result->{$_->[0]}
                    )
                );
            }
        }
    }
}

sub check_psu {
    my ($self) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rlEnvMonSupplyStatusEntry}})) {
        next if ($oid !~ /^$mapping->{rlEnvMonSupplyState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_rlEnvMonSupplyStatusEntry}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));
        if ($result->{rlEnvMonSupplyState} =~ /notPresent/i) {  
            $self->absent_problem(section => 'psu', instance => $instance);
            next;
        }

        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' status is '%s' [instance: %s]",
                $result->{rlEnvMonSupplyStatusDescr},
                $result->{rlEnvMonSupplyState},
                $instance
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'psu', value => $result->{rlEnvMonSupplyState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Power supply '%s' status is '%s'",
                    $result->{rlEnvMonSupplyStatusDescr},
                    $result->{rlEnvMonSupplyState}
                )
            );
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    check_psu($self);
    check_psu_stack($self);
}

1;
