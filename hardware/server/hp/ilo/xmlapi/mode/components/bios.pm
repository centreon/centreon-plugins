#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package hardware::server::hp::ilo::xmlapi::mode::components::bios;

use strict;
use warnings;

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking bios");
    $self->{components}->{bios} = {name => 'bios', total => 0, skip => 0};
    return if ($self->check_filter(section => 'bios'));
    return if (!defined($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{HEALTH_AT_A_GLANCE}->{BIOS_HARDWARE}));

    #<HEALTH_AT_A_GLANCE>
    #     <BIOS_HARDWARE STATUS= "OK"/>
    my $status = $self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{HEALTH_AT_A_GLANCE}->{BIOS_HARDWARE}->{STATUS};
    next if ($status =~ /not installed|n\/a|not present|not applicable/i &&
             $self->absent_problem(section => 'bios'));

    $self->{components}->{bios}->{total}++;

    $self->{output}->output_add(long_msg => sprintf("BIOS status is '%s'",
                                                    $status));

    my $exit = $self->get_severity(label => 'default', section => 'bios', value => $status);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("BIOS status is '%s'", $status));
    }
}

1;