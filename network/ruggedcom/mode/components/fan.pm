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

package network::ruggedcom::mode::components::fan;

use strict;
use warnings;

my %map_states_fan = (
    1 => 'notPresent',
    2 => 'failed',
    3 => 'standby',
    4 => 'off',
    5 => 'on',
);

my $oid_rcDeviceStsFanBank1_entry = '.1.3.6.1.4.1.15004.4.2.2.10';
my $oid_rcDeviceStsFanBank1 = '.1.3.6.1.4.1.15004.4.2.2.10.0';
my $oid_rcDeviceStsFanBank2_entry = '.1.3.6.1.4.1.15004.4.2.2.11';
my $oid_rcDeviceStsFanBank2 = '.1.3.6.1.4.1.15004.4.2.2.11.0';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_rcDeviceStsFanBank1_entry }, { oid => $oid_rcDeviceStsFanBank2_entry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    my $instance = 0;
    foreach my $value (($self->{results}->{$oid_rcDeviceStsFanBank1}, $self->{results}->{$oid_rcDeviceStsFanBank2})) {
        $instance++;
        next if (!defined($value));
        my $fan_state = $value;

        next if ($self->check_filter(section => 'fan', instance => $instance));
        next if ($map_states_fan{$fan_state} eq 'notPresent' && 
                 $self->absent_problem(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("fan Bank '%s' state is %s.",
                                    $instance, $map_states_fan{$fan_state}));
        my $exit = $self->get_severity(section => 'fan', value => $map_states_fan{$fan_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan Bank '%s' state is %s.", $instance, $map_states_fan{$fan_state}));
        }
    }
}

1;
