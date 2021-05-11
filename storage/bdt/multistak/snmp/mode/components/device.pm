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

package storage::bdt::multistak::snmp::mode::components::device;

use strict;
use warnings;

my $map_health = {
    1 => 'unknown', 2 => 'ok', 3 => 'warning', 4 => 'critical'
};

my $mapping = {
    health => { oid => '.1.3.6.1.4.1.20884.2.3', map => $map_health } # bdtDeviceStatHealth
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $mapping->{health}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking device');
    $self->{components}->{device} = { name => 'device', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'device'));

    my $instance = 0;
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{health}->{oid} }, instance => $instance);
    return if (!defined($result->{health}));

    $self->{components}->{device}->{total}++;
    $self->{output}->output_add(
        long_msg => sprintf(
            "device health status is '%s' [instance: %s]",
            $result->{health}, $instance
        )
    );
    my $exit = $self->get_severity(label => 'health', section => 'device', instance => $instance, value => $result->{health});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity =>  $exit,
            short_msg => sprintf(
                "Device health status is '%s'",
                $result->{health}
            )
        );
    }
}

1;
