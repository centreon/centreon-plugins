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

package storage::lenovo::iomega::snmp::mode::components::voltage;

use strict;
use warnings;

my $mapping = {
    voltName  => { oid => '.1.3.6.1.4.1.11369.10.6.3.1.2' },
    voltValue => { oid => '.1.3.6.1.4.1.11369.10.6.3.1.3' }
};
my $oid_voltEntry = '.1.3.6.1.4.1.11369.10.6.3.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { 
        oid => $oid_voltEntry,
        start => $mapping->{voltName}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking voltages');
    $self->{components}->{voltage} = { name => 'voltages', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'voltage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $oid_voltEntry }})) {
        next if ($oid !~ /^$mapping->{voltValue}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $oid_voltEntry }, instance => $instance);

        next if ($self->check_filter(section => 'voltage', instance => $instance));

        $self->{components}->{voltage}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "voltage '%s' is '%s' mV [instance = %s]",
                $result->{voltName}, $result->{voltValue}, $instance
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{voltValue});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "voltage '%s' is '%s' mV", $result->{voltName}, $result->{voltValue}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.voltage.millivolt',
            unit => 'mV',
            instances => $result->{voltName},
            value => $result->{voltValue},
            warning => $warn,
            critical => $crit, min => 0
        );
    }
}

1;
