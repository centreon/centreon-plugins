#
# Copyright 2018 Centreon (http://www.centreon.com/)
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
# Author : ArnoMLT
#

package network::atto::fibrebridge::snmp::mode::components::alarm;

use strict;
use warnings;

my %map_throughput_status = (
    1 => 'normal', 2 => 'warning'
);
my $oid_chassisThroughputStatus = '.1.3.6.1.4.1.4547.2.3.2.11.0';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, $oid_chassisThroughputStatus;
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "checking alarms");
    $self->{components}->{alarm} = { name => 'alarms', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'alarm'));

    return if (!defined($self->{results}->{$oid_chassisThroughputStatus}));
    my ($instance, $name) = (1, 'throughput');
    my $status = $map_throughput_status{$self->{results}->{$oid_chassisThroughputStatus}};
        
    next if ($self->check_filter(section => 'alarm', instance => $instance, name => $name));
    $self->{components}->{alarm}->{total}++;
    
    $self->{output}->output_add(long_msg => sprintf("alarm '%s' status is %s [instance = %s]", 
                                    $name, $status, $instance));
    my $exit = $self->get_severity(section => 'alarm', value => $status);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Alarm '%s' status is %s", $name, $status));
    }
}

1;
