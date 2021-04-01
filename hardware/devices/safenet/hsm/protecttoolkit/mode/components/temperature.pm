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

package hardware::devices::safenet::hsm::protecttoolkit::mode::components::temperature;

use strict;
use warnings;

sub load { }

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperature");
    return if ($self->check_filter(section => 'temperature'));
    
    return if ($self->{stdout} !~ /^Temperature\s+:\s+(\d+)/msi);
    my $temperature = $1;

    $self->{output}->output_add(long_msg => sprintf("temperature is %d C", 
                                                    $temperature));
    my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => '0', value => $temperature);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Temperature is %s C", $temperature));
    }
    $self->{output}->perfdata_add(
        label => "temp", unit => 'C',
        nlabel => 'hardware.temperature.celsius',
        value => $temperature,
        warning => $warn,
        critical => $crit
    );
}

1;
