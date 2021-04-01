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

package hardware::devices::cisco::ces::restapi::mode::components::temperature;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking temperature');
    $self->{components}->{temperature} = { name => 'temperature', total => 0, skip => 0 }  ;
    return if ($self->check_filter(section => 'temperature'));

    my $temp_status = $self->{results}->{SystemUnit}->{Hardware}->{Monitoring}->{Temperature}->{Status};
    $temp_status = 'n/a' if (!defined($temp_status));
    my $temp_value = ref($self->{results}->{SystemUnit}->{Hardware}->{Temperature}) eq 'HASH' ?
        $self->{results}->{SystemUnit}->{Hardware}->{Temperature}->{content} : undef;

    return if (!defined($temp_status) && !defined($temp_value));

    my $instance = 1;
    return if ($self->check_filter(section => 'temperature', instance => $instance));
    $self->{components}->{temperature}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            "temperature '%s' status is '%s' [instance: %s, value: %s]",
            $instance,
            $temp_status,
            $instance,
            defined($temp_value) ? $temp_value : '-'
        )
    );

    my $exit = $self->get_severity(section => 'temperature', value => $temp_status);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf("temperature '%s' status is '%s'", $instance, $temp_status)
        );
    }

    return if (!defined($temp_value));

    my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $temp_value);

    if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "temperature '%s' is %s C",
                $instance, $temp_value
            )
        );
    }
    $self->{output}->perfdata_add(
        unit => 'C',
        nlabel => 'component.hardware.temperature.celsius',
        instances => 'system',
        value => $temp_value,
        warning => $warn,
        critical => $crit
    );
}

1;
