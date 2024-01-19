#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::fortinet::fortiadc::snmp::mode::components::fan;

use strict;
use warnings;

my $mapping_fan = {
    name   => { oid => '.1.3.6.1.4.1.12356.112.6.4.2.1.1.2' }, # fadcDeviceFanName
    speed  => { oid => '.1.3.6.1.4.1.12356.112.6.4.2.1.1.3' }, # fadcDeviceFanSpeed
    status => { oid => '.1.3.6.1.4.1.12356.112.6.4.2.1.1.4' }  # fadcDeviceFanStatus
};
my $oid_fanTable = '.1.3.6.1.4.1.12356.112.6.4.2.1'; # fadcDeviceFanTable

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_fanTable, start => $mapping_fan->{name}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking fans');
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fanTable}})) {
        next if ($oid !~ /^$mapping_fan->{status}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_fan, results => $self->{results}->{$oid_fanTable}, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance, name => $result->{name}));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is %s [instance: %s, speed: %s]",
                $result->{name},
                $result->{status},
                $instance,
                $result->{speed}
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "fan '%s' status is %s",
                    $result->{name}, $result->{status}
                )
            );
        }
        
        next if (!defined($result->{speed}));

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, name => $result->{name}, value => $result->{speed});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "fan '%s' speed is %s rpm",
                    $result->{name},
                    $result->{speed}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.fan.speed.rpm',
            unit => 'rpm',
            instances => $result->{name},
            value => $result->{speed},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

1;
