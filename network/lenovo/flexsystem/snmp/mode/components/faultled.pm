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

package network::lenovo::flexsystem::snmp::mode::components::faultled;

use strict;
use warnings;

my %map_faultled_states = ( 1 => 'on', 2 => 'off' );

sub load {}

sub check_faultled {
    my ($self, %options) = @_;

    $self->{components}->{faultled}->{total}++;

    $self->{output}->output_add(long_msg => 
        sprintf(
            "Fault LED state is %s",
             $options{value}
        )
    );
    my $exit = $self->get_severity(section => 'faultled', value => $options{value});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "Fault LED state is %s",
                $options{value}
            )
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking fault LED');
    $self->{components}->{faultled} = { name => 'faultled', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'faultled'));

    my $oid_mmspFaultLED = '.1.3.6.1.4.1.20301.2.5.1.3.10.12.0';
    my $results = $self->{snmp}->get_leef(oids => [$oid_mmspFaultLED]);
    return if (!defined($results->{$oid_mmspFaultLED}));

    check_faultled($self, value => $map_faultled_states{$results->{$oid_mmspFaultLED}});
}

1;
