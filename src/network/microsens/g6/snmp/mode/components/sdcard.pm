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

package network::microsens::g6::snmp::mode::components::sdcard;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking sd cards');
    $self->{components}->{sdcard} = { name => 'sdcard', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'sdcard'));

    return if (!defined($self->{results}->{sdcard_status}) || $self->check_filter(section => 'sdcard', instance => 1));

    $self->{output}->output_add(
        long_msg => sprintf(
            "sd card '1' status is %s",
            $self->{results}->{sdcard_status}
        )
    );
    $self->{components}->{sdcard}->{total}++;

    my $exit = $self->get_severity(section => 'sdcard', instance => 1, value => $self->{results}->{sdcard_status});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity =>  $exit,
            short_msg => sprintf(
                "sd card '1' status is %s",
                $self->{results}->{sdcard_status}
            )
        );
    }
}

1;
