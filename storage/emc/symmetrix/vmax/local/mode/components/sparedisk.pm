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

package storage::emc::symmetrix::vmax::local::mode::components::sparedisk;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

#06/15/2016 09:26:42.015 Verify Spare Status Test
#There are 1 non available Spare[s], deferred service is ON.
#06/15/2016 09:26:42.046 Verify Spare Status: Test Succeeded.

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking spare disks");
    $self->{components}->{sparedisk} = {name => 'spare disks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sparedisk'));
    
    if ($self->{content_file_health} !~ /There are (\d+) non available Spare/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find spare disks');
        return ;
    }
    
    my $value = $1;    
    $self->{components}->{sparedisk}->{total}++;

    my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'sparedisk', instance => '1', value => $value);
    $self->{output}->output_add(long_msg => sprintf("'%s' spare disk non availabled", 
                                                    $value));
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("'%s' spare disk non availabled", 
                                                    $value));
    }
    
    $self->{output}->perfdata_add(
        label => "disk_spare_non_available",
        nlabel => 'hardware.sparedisk.unavailable.count',
        value => $value,
        warning => $warn,
        critical => $crit, min => 0
    );
}

1;
