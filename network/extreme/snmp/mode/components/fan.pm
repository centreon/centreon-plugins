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

package network::extreme::snmp::mode::components::fan;

use strict;
use warnings;

my %map_fan_status = (
    1 => 'operational',
    2 => 'not operational',
);

my $mapping = {
    extremeFanOperational => { oid => '.1.3.6.1.4.1.1916.1.1.1.9.1.2', map => \%map_fan_status },
    extremeFanSpeed => { oid => '.1.3.6.1.4.1.1916.1.1.1.9.1.4' },
};
my $oid_extremeFanStatusEntry = '.1.3.6.1.4.1.1916.1.1.1.9.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { 
        oid => $oid_extremeFanStatusEntry,
        start => $mapping->{extremeFanOperational}->{oid},
        end => $mapping->{extremeFanSpeed}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_extremeFanStatusEntry}})) {
        next if ($oid !~ /^$mapping->{extremeFanOperational}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_extremeFanStatusEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'fan', instance => $instance));

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => 
            sprintf(
                "Fan '%s' status is '%s' [instance = %s, speed = %s]",
                $instance,
                $result->{extremeFanOperational},
                $instance,
                defined($result->{extremeFanSpeed}) ? $result->{extremeFanSpeed} : 'unknown'
            )
        );
        $exit = $self->get_severity(section => 'fan', value => $result->{extremeFanOperational});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Fan '%s' status is '%s'",
                    $instance,
                    $result->{extremeFanOperational}
                )
            );
        }
        
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{extremeFanSpeed});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Fan '%s' is '%s' rpm",
                    $instance,
                    $result->{extremeFanSpeed}
                )
            );
        }
        $self->{output}->perfdata_add(
            label => 'fan', unit => 'rpm',
            nlabel => 'hardware.fan.speed.rpm',
            instances => $instance, 
            value => $result->{extremeFanSpeed},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

1;
