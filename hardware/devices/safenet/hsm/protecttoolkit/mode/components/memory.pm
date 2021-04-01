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

package hardware::devices::safenet::hsm::protecttoolkit::mode::components::memory;

use strict;
use warnings;

sub load { }

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking memory");
    return if ($self->check_filter(section => 'memory'));
    
    return if ($self->{stdout} !~ /^SM Size Free\/Total\s*:\s+(\d+)\/(\d+)/msi);
    my ($free, $total) = ($1, $2);
    my $used = $total - $free;
    my $prct_used = $used * 100 / $total;
    my $prct_free = 100 - $prct_used;

    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $free);
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $used);
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total);
    my $message = sprintf("Memory Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                                            $total_value . " " . $total_unit,
                                            $used_value . " " . $used_unit, $prct_used,
                                            $free_value . " " . $free_unit, $prct_free);
    $self->{output}->output_add(long_msg => $message);
    my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'memory', instance => '0', value => $prct_used);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => $message);
    }
    $self->{output}->perfdata_add(
        label => "used_memory", unit => 'B',
        nlabel => 'hardware.memory.usage.bytes',
        value => $used,
        warning => $warn,
        critical => $crit, min => 0, total => $total
    );
}

1;
