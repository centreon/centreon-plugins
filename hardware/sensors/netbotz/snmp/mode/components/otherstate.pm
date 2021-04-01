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

package hardware::sensors::netbotz::snmp::mode::components::otherstate;

use strict;
use warnings;
use hardware::sensors::netbotz::snmp::mode::components::resources qw($map_status);

sub load {
    my ($self) = @_;

    $self->{mapping_otherstate} = {
        otherStateSensorId          => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.10.1.1' },
        otherStateSensorErrorStatus => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.10.1.3', map => $map_status },
        otherStateSensorLabel       => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.10.1.4' },
        otherStateSensorValueStr    => { oid => '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.10.1.7' }
    };
    $self->{oid_otherStateSensorEntry} = '.1.3.6.1.4.1.' . $self->{netbotz_branch} . '.4.2.10.1';
    push @{$self->{request}}, { oid => $self->{oid_otherStateSensorEntry} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking other state");
    $self->{components}->{otherstate} = { name => 'other state', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'otherstate'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{oid_otherStateSensorEntry} }})) {
        next if ($oid !~ /^$self->{mapping_otherstate}->{otherStateSensorErrorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping => $self->{mapping_otherstate},
            results => $self->{results}->{ $self->{oid_otherStateSensorEntry} },
            instance => $instance
        );

        next if ($self->check_filter(section => 'otherstate', instance => $instance));
        $self->{components}->{otherstate}->{total}++;

        my $label = defined($result->{otherStateSensorLabel}) && $result->{otherStateSensorLabel} ne '' ? $result->{otherStateSensorLabel} : $result->{otherStateSensorId};
        $self->{output}->output_add(
            long_msg => sprintf(
                "other state '%s' status is '%s' [instance = %s] [value = %s]",
                $label,
                $result->{otherStateSensorErrorStatus},
                $instance, 
                $result->{otherStateSensorValueStr}
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'otherstate', value => $result->{otherStateSensorErrorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Other state '%s' status is '%s'",
                    $label,
                    $result->{otherStateSensorErrorStatus}
                )
            );
        }
    }
}

1;
