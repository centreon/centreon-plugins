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

package network::fortinet::fortiadc::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping_cpu = {
    name    => { oid => '.1.3.6.1.4.1.12356.112.6.1.1.1.2' }, # fadcCPUName
    current => { oid => '.1.3.6.1.4.1.12356.112.6.1.1.1.3' }  # fadcCPUTemp
};
my $oid_cpuTable = '.1.3.6.1.4.1.12356.112.6.1.1'; # fadcCPUTable

my $mapping_temp = {
    name    => { oid => '.1.3.6.1.4.1.12356.112.6.4.1.1.1.2' }, # fadcDeviceTempName
    current => { oid => '.1.3.6.1.4.1.12356.112.6.4.1.1.1.3' }  # fadcDeviceTempValue
};
my $oid_tempTable = '.1.3.6.1.4.1.12356.112.6.4.1.1'; # fadcDeviceTempTable

sub load {
    my ($self) = @_;
    
    push @{$self->{request}},
        { oid => $oid_cpuTable, start => $mapping_cpu->{name}->{oid} },
        { oid => $oid_tempTable, start => $mapping_temp->{name}->{oid} }
    ;
}

sub check_temperature {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $options{entry} }})) {
        next if ($oid !~ /^$options{mapping}->{current}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{ $options{entry} }, instance => $instance);

        $instance = $options{type} . '.' . $instance;
        next if ($self->check_filter(section => 'temperature', instance => $instance, name => $result->{name}));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' is %s C [instance: %s]",
                $result->{name},
                $result->{current},
                $instance,
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, name => $result->{name}, value => $result->{current});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "temperature '%s' is %s degree centigrate",
                    $result->{name},
                    $result->{current}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.celsius',
            unit => 'C',
            instances => $result->{name},
            value => $result->{current},
            warning => $warn,
            critical => $crit
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking temperatures');
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    check_temperature($self, entry => $oid_cpuTable, mapping => $mapping_cpu, type => 'cpu');
    check_temperature($self, entry => $oid_tempTable, mapping => $mapping_temp, type => 'device');
}

1;
