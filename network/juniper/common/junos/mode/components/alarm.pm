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

package network::juniper::common::junos::mode::components::alarm;

use strict;
use warnings;

my %map_alarm_states = (
    1 => 'other', 
    2 => 'off', 
    3 => 'on', 
);

sub check_alarm {
    my ($self, %options) = @_;

    return if ($self->check_filter(section => 'alarm', instance => $options{instance}, name => $options{name}));
    $self->{components}->{alarm}->{total}++;
        
    $self->{output}->output_add(long_msg => 
        sprintf(
            "alarm '%s' state is %s [instance: %s]", 
             $options{name}, $options{value}, $options{instance}
        )
    );
    my $exit = $self->get_severity(section => 'alarm', instance => $options{instance}, value => $options{value});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "Alarm '%s' state is %s", 
                $options{name}, $options{value}
            )
        );
    }
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking alarms");
    $self->{components}->{alarm} = { name => 'alarm', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'alarm'));

    my $oid_jnxYellowAlarmState = '.1.3.6.1.4.1.2636.3.4.2.2.1.0';
    my $oid_jnxRedAlarmState = '.1.3.6.1.4.1.2636.3.4.2.3.1.0';
    my $results = $self->{snmp}->get_leef(oids => [$oid_jnxYellowAlarmState, $oid_jnxRedAlarmState]);

    check_alarm($self, instance => 0, name => 'yellow', value => $map_alarm_states{$results->{$oid_jnxYellowAlarmState}})
        if (defined($results->{$oid_jnxYellowAlarmState}));
    check_alarm($self, instance => 1, name => 'red', value => $map_alarm_states{$results->{$oid_jnxRedAlarmState}})
        if (defined($results->{$oid_jnxRedAlarmState}));
}

1;
