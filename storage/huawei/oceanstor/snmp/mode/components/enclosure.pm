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

package storage::huawei::oceanstor::snmp::mode::components::enclosure;

use strict;
use warnings;
use storage::huawei::oceanstor::snmp::mode::resources qw($health_status $running_status);

my $mapping = {
    id             => { oid => '.1.3.6.1.4.1.34774.4.1.23.5.6.1.1' }, # hwInfoEnclosureID
    name           => { oid => '.1.3.6.1.4.1.34774.4.1.23.5.6.1.2' }, # hwInfoEnclosureName
    health_status  => { oid => '.1.3.6.1.4.1.34774.4.1.23.5.6.1.4', map => $health_status }, # hwInfoEnclosureHealthStatus
    running_status => { oid => '.1.3.6.1.4.1.34774.4.1.23.5.6.1.5', map => $running_status }, # hwInfoEnclosureRunningStatus
    temperature    => { oid => '.1.3.6.1.4.1.34774.4.1.23.5.6.1.8' } # hwInfoEnclosureTemperature
};
my $oid_enclosure_entry = '.1.3.6.1.4.1.34774.4.1.23.5.6.1'; # hwInfoEnclosureEntry

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_enclosure_entry, 
        end => $mapping->{temperature}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking enclosures');
    $self->{components}->{enclosure} = { name => 'enclosures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'enclosure'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_enclosure_entry}})) {
        next if ($oid !~ /^$mapping->{id}->{oid}\.(.*)$/);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_enclosure_entry}, instance => $1);
        my $instance = $result->{id};
        my $name = $result->{name};

        next if ($self->check_filter(section => 'enclosure', instance => $instance, name => $name));
        
        $self->{components}->{enclosure}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "enclosure '%s' status is '%s' [instance: %s, name: %s, running status: %s, temperature: %s]",
                $instance,
                $result->{health_status},
                $instance,
                $result->{name},
                $result->{running_status},
                $result->{temperature}
            )
        );
        $exit = $self->get_severity(label => 'default', section => 'enclosure', name => $name, value => $result->{health_status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Enclosure '%s' status is '%s'",
                    $instance,
                    $result->{health_status}
                )
            );
        }

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'enclosure.temperature', instance => $instance, name => $name, value => $result->{temperature});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Enclosure temperature '%s' is '%s' C", $instance, $result->{temperature})
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.enclosure.temperature.celsius',
            unit => 'C',
            instances => $instance,
            value => $result->{temperature},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
