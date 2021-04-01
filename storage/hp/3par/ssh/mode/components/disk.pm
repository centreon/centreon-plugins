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

package storage::hp::3par::ssh::mode::components::disk;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    # Id State
    #  0 normal
    #  1 normal
    #  2 normal
    #...
    # 10 normal
    # 11 normal 
    push @{$self->{commands}}, 'echo "===showdisk==="', 'showpd -showcols Id,State';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = { name => 'disks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));

    return if ($self->{results} !~ /===showdisk===.*?\n(.*?)(===|\Z)/msi);
    my @results = split /\n/, $1;

    foreach (@results) {
        next if (!/^\s*(\d+)\s+(\S+)/);
        my ($instance, $state) = ($1, $2);

        next if ($self->check_filter(section => 'disk', instance => $instance));
        $self->{components}->{disk}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("disk '%s' state is '%s' [instance: '%s']",
                                    $instance, $state, $instance)
                                    );
        my $exit = $self->get_severity(label => 'default', section => 'disk', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Disk '%s' state is '%s'",
                                                             $instance, $state));
        }
    }
}

1;
