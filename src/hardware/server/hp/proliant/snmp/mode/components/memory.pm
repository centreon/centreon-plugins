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

package hardware::server::hp::proliant::snmp::mode::components::memory;

use strict;
use warnings;

my %map_memory_status = (
    1 => 'other',
    2 => 'notPresent',
    3 => 'present',
    4 => 'good',
    5 => 'add',
    6 => 'upgrade',
    7 => 'missing',
    8 => 'doesNotMatch',
    9 => 'notSupported',
    10 => 'badConfig',
    11 => 'degraded',
    12 => 'spare',
    13 => 'partial',
    14 => 'configError',
    15 => 'trainingFailure'
);

my $mapping = {
    size     => { oid => '.1.3.6.1.4.1.232.6.2.14.13.1.6' }, # cpqHeResMem2ModuleSize
    location => { oid => '.1.3.6.1.4.1.232.6.2.14.13.1.13' }, # cpqHeResMem2ModuleHwLocation
    status   => { oid => '.1.3.6.1.4.1.232.6.2.14.13.1.19', map => \%map_memory_status } # cpqHeResMem2ModuleStatus
};
my $oid_cpqHeResMem2Module = '.1.3.6.1.4.1.232.6.2.14.13.1.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_cpqHeResMem2Module };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking memory");
    $self->{components}->{memory} = { name => 'memory', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'memory'));

    return if (scalar(keys %{$self->{results}->{$oid_cpqHeResMem2Module}}) <= 0);

    $self->{snmp}->load(
        oids => [map($_->{oid}, values(%$mapping))],
        instances => [values(%{$self->{results}->{$oid_cpqHeResMem2Module}})]
    );
    my $results = $self->{snmp}->get_leef();

    foreach my $instance (sort values(%{$self->{results}->{$oid_cpqHeResMem2Module}})) {
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        next if ($self->check_filter(section => 'memory', instance => $instance));
        $self->{components}->{memory}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "memory slot '%s' [location: %s, size: %skB] status is %s", 
                $instance,
                defined($result->{location}) ? $result->{location} : '-',
                $result->{size},
                $result->{status}
            )
        );
        my $exit = $self->get_severity(section => 'memory', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "memory slot '%s' is %s", 
                    $instance, $result->{status}
                )
            );
        }
    }
}

1;
