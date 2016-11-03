#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package hardware::devices::safenet::hsm::protecttoolkit::mode::components::memory;

use strict;
use warnings;

sub load { }

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking memory");
    return if ($self->check_filter(section => 'memory'));
    
    return if ($self->{stdout} !~ /^Free Memory\s+:\s+(\d+)/msi);
    my $free_memory = $1;

    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $free_memory);
    $self->{output}->output_add(long_msg => sprintf("free memory is %s %s", 
                                                    $free_value, $free_unit));
    my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'memory', instance => '0', value => $free_memory);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Free memory is %s %s", $free_value, $free_unit));
    }
    $self->{output}->perfdata_add(label => "free_memory", unit => 'B',
                                  value => $free_memory,
                                  warning => $warn,
                                  critical => $crit, min => 0);
}

1;