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

package network::juniper::common::junos::mode::components::operating;

use strict;
use warnings;

my %map_operating_states = (
    1 => 'unknown', 
    2 => 'running', 
    3 => 'ready', 
    4 => 'reset',
    5 => 'runningAtFullSpeed',
    6 => 'down',
    7 => 'standby',
);

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking operatings");
    $self->{components}->{operating} = { name => 'operatings', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'operating'));

    my $mapping = {
        jnxOperatingState => { oid => '.1.3.6.1.4.1.2636.3.1.13.1.6', map => \%map_operating_states },
        jnxOperatingTemp => { oid => '.1.3.6.1.4.1.2636.3.1.13.1.7' },
        jnxOperatingCPU => { oid => '.1.3.6.1.4.1.2636.3.1.13.1.8' },
        jnxOperatingBuffer => { oid => '.1.3.6.1.4.1.2636.3.1.13.1.11' },
        jnxOperatingHeap => { oid => '.1.3.6.1.4.1.2636.3.1.13.1.12' },
    };

    my $results = $self->{snmp}->get_table(
        oid => $self->{oids_operating}->{jnxOperatingEntry},
        start => $mapping->{jnxOperatingState}->{oid},
        end => $mapping->{jnxOperatingHeap}->{oid}
    );
    
    foreach my $instance (sort $self->get_instances(oid_entry => $self->{oids_operating}->{jnxOperatingEntry},
        oid_name => $self->{oids_operating}->{jnxOperatingDescr})) {
        my $result = $self->{snmp}->map_instance(
            mapping => $mapping,
            results => $results,
            instance => $instance
        );        
        my $description = $self->get_cache(
            oid_entry => $self->{oids_operating}->{jnxOperatingEntry},
            oid_name => $self->{oids_operating}->{jnxOperatingDescr},
            instance => $instance
        );

        next if ($self->check_filter(section => 'operating', instance => $instance, name => $description));
        $self->{components}->{operating}->{total}++;
        
        $self->{output}->output_add(
            long_msg => sprintf("operating '%s' state is %s [instance: %s]", 
                $description,
                $result->{jnxOperatingState},
                $instance)
        );
        my $exit = $self->get_severity(section => 'operating', instance => $instance,
            value => $result->{jnxOperatingState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Operating '%s' state is %s", 
                    $description,
                    $result->{jnxOperatingState})
            );
        }
        
        if (defined($result->{jnxOperatingTemp}) && $result->{jnxOperatingTemp} != 0) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
                section => 'operating-temperature',
                instance => $instance,
                name => $description,
                value => $result->{jnxOperatingTemp}
            );
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Operating '%s' temperature is %s degree centigrade",
                        $description,
                        $result->{jnxOperatingTemp})
                );
            }
            $self->{output}->perfdata_add(
                label => "temp", unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => $description,
                value => $result->{jnxOperatingTemp},
                warning => $warn,
                critical => $crit
            );
        }
        if (defined($result->{jnxOperatingCPU}) && $result->{jnxOperatingCPU} != 0) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
                section => 'operating-cpu',
                instance => $instance,
                name => $description,
                value => $result->{jnxOperatingCPU}
            );
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Operating '%s' CPU utilization is %s%%",
                        $description,
                        $result->{jnxOperatingCPU})
                );
            }
            $self->{output}->perfdata_add(
                label => "cpu_utilization", unit => '%',
                nlabel => 'hardware.cpu.utilization.percentage',
                instances => $description,
                value => $result->{jnxOperatingCPU},
                warning => $warn,
                critical => $crit
            );
        }
        if (defined($result->{jnxOperatingBuffer}) && $result->{jnxOperatingBuffer} != 0) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
                section => 'operating-buffer',
                instance => $instance,
                name => $description,
                value => $result->{jnxOperatingBuffer}
            );
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Operating '%s' buffer usage is %s%%",
                        $description,
                        $result->{jnxOperatingBuffer})
                );
            }
            $self->{output}->perfdata_add(
                label => "buffer_usage", unit => '%',
                nlabel => 'hardware.buffer.usage.percentage',
                instances => $description,
                value => $result->{jnxOperatingBuffer},
                warning => $warn,
                critical => $crit
            );
        }
        if (defined($result->{jnxOperatingHeap}) && $result->{jnxOperatingHeap} != 0) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(
                section => 'operating-heap',
                instance => $instance,
                name => $description,
                value => $result->{jnxOperatingHeap}
            );
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Operating '%s' heap usage is %s%%",
                        $description,
                        $result->{jnxOperatingHeap})
                );
            }
            $self->{output}->perfdata_add(
                label => "heap_usage", unit => '%',
                nlabel => 'hardware.heap.usage.percentage',
                instances => $description,
                value => $result->{jnxOperatingHeap},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
