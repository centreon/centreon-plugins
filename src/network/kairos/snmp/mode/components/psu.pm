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

package network::microsens::g6::snmp::mode::components::psu;

use strict;
use warnings;

sub load {}

sub check_psu {
    my ($self, %options) = @_;

    $self->{output}->output_add(
        long_msg => sprintf(
            "power supply '%s' status is %s",
            $options{name},
            $options{value}
        )
    );
    $self->{components}->{psu}->{total}++;

    my $exit = $self->get_severity(section => 'psu', instance => $options{name}, value => $options{value});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity =>  $exit,
            short_msg => sprintf(
                "power supply '1' status is %s",
                $options{name},
                $options{value}
            )
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking power supplies');
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    if (defined($self->{results}->{psu1_status}) && !$self->check_filter(section => 'psu', instance => 1)) {
        check_psu(
            $self,
            value => $self->{results}->{psu1_status},
            name => 1
        );
    }
    if (defined($self->{results}->{psu2_status}) && !$self->check_filter(section => 'psu', instance => 2)) {
        check_psu(
            $self,
            value => $self->{results}->{psu2_status},
            name => 2
        );
    }
}

1;
