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

package storage::lenovo::iomega::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    tempName  => { oid => '.1.3.6.1.4.1.11369.10.6.2.1.2' },
    tempValue => { oid => '.1.3.6.1.4.1.11369.10.6.2.1.3' }
};
my $oid_tempEntry = '.1.3.6.1.4.1.11369.10.6.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { 
        oid => $oid_tempEntry,
        start => $mapping->{tempName}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking temperatures');
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $oid_tempEntry }})) {
        next if ($oid !~ /^$mapping->{tempValue}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $oid_tempEntry }, instance => $instance);

        next if ($self->check_filter(section => 'temperature', instance => $instance));

        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' is '%s' celsius [instance = %s]",
                $result->{tempName}, $result->{tempValue}, $instance
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{tempValue});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "temperature '%s' is '%s' celsius", $result->{tempName}, $result->{tempValue}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.celsius',
            unit => 'C',
            instances => $result->{tempName},
            value => $result->{tempValue},
            warning => $warn,
            critical => $crit, min => 0
        );
    }
}

1;
