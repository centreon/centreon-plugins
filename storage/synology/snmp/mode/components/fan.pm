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

package storage::synology::snmp::mode::components::fan;

use strict;
use warnings;

my $map_status = { 1 => 'Normal', 2 => 'Failed' };

my $mapping = {
    synoSystemsystemFanStatus => { oid => '.1.3.6.1.4.1.6574.1.4.1', map => $map_status  },
    synoSystemcpuFanStatus    => { oid => '.1.3.6.1.4.1.6574.1.4.2', map => $map_status  }
};
my $oid_fan = '.1.3.6.1.4.1.6574.1.4';

sub load {
    my ($self) = @_;
    
    push @{$self->{request_leef}}, $mapping->{synoSystemsystemFanStatus}->{oid} . '.0', $mapping->{synoSystemcpuFanStatus}->{oid} . '.0';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cpu fan");
    $self->{components}->{fan} = {name => 'fan', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results_leef}, instance => '0');
    if (defined($result->{synoSystemcpuFanStatus}) && !$self->check_filter(section => 'fan', instance => 'cpu')) {
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "cpu fan state is %s.",
                $result->{synoSystemcpuFanStatus}
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'fan', instance => 'cpu', value => $result->{synoSystemcpuFanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("CPU fan status is %s", $result->{synoSystemcpuFanStatus})
            );
        }
    }
    
    if (defined($result->{synoSystemsystemFanStatus}) && !$self->check_filter(section => 'fan', instance => 'system')) {
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "system fan state is %s.",
                $result->{synoSystemsystemFanStatus}
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'fan', instance => 'system', value => $result->{synoSystemsystemFanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("System fan status is %s", $result->{synoSystemsystemFanStatus})
            );
        }
    }
}

1;
