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

package network::allied::snmp::mode::components::psu;

use strict;
use warnings;

my $map_status = {
    1 => 'failed', 2 => 'good', 3 => 'notPowered'
};

my $mapping = {
    atEnvMonv2PsbSensorDescription    => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.4.2.1.5' },
    atEnvMonv2PsbSensorStatus         => { oid => '.1.3.6.1.4.1.207.8.4.4.3.12.4.2.1.6', map => $map_status },
};
my $oid_atEnvMonv2PsbSensorEntry = '.1.3.6.1.4.1.207.8.4.4.3.12.4.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { 
        oid => $oid_atEnvMonv2PsbSensorEntry,
        start => $mapping->{atEnvMonv2PsbSensorDescription}->{oid},
        end => $mapping->{atEnvMonv2PsbSensorStatus}->{oid}
    };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "checking power supplies");
    $self->{components}->{psu} = { name => 'psus', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_atEnvMonv2PsbSensorEntry}})) {
        next if ($oid !~ /^$mapping->{atEnvMonv2PsbSensorStatus}->{oid}\.(\d+)\.(\d+)\.(\d+)$/);
        my ($stack_id, $board_index, $psu_index) = ($1, $2, $3);
        my $instance = $stack_id . '.' . $board_index . '.' . $psu_index; 
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_atEnvMonv2PsbSensorEntry}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' status is %s [instance: %s, stack: %s, board: %s]",
                $result->{atEnvMonv2PsbSensorDescription}, 
                $result->{atEnvMonv2PsbSensorStatus},
                $instance,
                $stack_id,
                $board_index
            )
        );
        my $exit = $self->get_severity(section => 'psu', value => $result->{atEnvMonv2PsbSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "power supply '%s' status is %s",
                    $result->{atEnvMonv2PsbSensorDescription},
                    $result->{atEnvMonv2PsbSensorStatus}
                )
            );
        }
    }
}

1;
