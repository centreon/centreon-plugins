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

package hardware::sensors::sensorip::snmp::mode::components::sp;

use strict;
use warnings;

my %map_sp_status = (
    1 => 'noStatus',
    2 => 'normal',
    3 => 'warning',
    4 => 'critical',
    5 => 'sensorError',
);
my $oid_spStatus = '.1.3.6.1.4.1.3854.1.1.2';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_spStatus };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sp");
    $self->{components}->{sp} = { name => 'sp', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'sp'));
    return if (scalar(keys %{$self->{results}->{$oid_spStatus}}) <= 0);

    my $instance = 0;
    my $sp_status = defined($map_sp_status{$self->{results}->{$oid_spStatus}->{$oid_spStatus . '.' . $instance}}) ?
                            $map_sp_status{$self->{results}->{$oid_spStatus}->{$oid_spStatus . '.' . $instance}} : 'unknown';

    return if ($self->check_filter(section => 'sp', instance => $instance));
    return if ($sp_status =~ /noStatus/i && 
               $self->absent_problem(section => 'sp', instance => $instance));
    
    $self->{components}->{sp}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("Sensor probe '%s' status is '%s'",
                                $instance, $sp_status));
    my $exit = $self->get_severity(section => 'sp', value => $sp_status);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Sensor probe '%s' status is '%s'", $instance, $sp_status));
    }
}

1;
