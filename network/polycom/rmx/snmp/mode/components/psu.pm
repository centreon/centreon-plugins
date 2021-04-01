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

package network::polycom::rmx::snmp::mode::components::psu;

use strict;
use warnings;

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    return if (!defined($self->{results}->{hardwarePowerSupplyStatus}));
    $self->{components}->{psu}->{total}++;
    
    $self->{output}->output_add(long_msg => sprintf("power supply status is '%s'",
                                                    $self->{results}->{hardwarePowerSupplyStatus}));
    my $exit = $self->get_severity(label => 'default', section => 'psu', value => $self->{results}->{hardwarePowerSupplyStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Power supply status is '%s'", $self->{results}->{hardwarePowerSupplyStatus}));
    }
}

1;