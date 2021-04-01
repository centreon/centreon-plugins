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

package storage::hp::3par::ssh::mode::components::node;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    #Node -State- -Detailed_State-
    #0 OK      OK              
    #1 OK      OK              
    #2 OK      OK              
    #3 OK      OK 
    push @{$self->{commands}}, 'echo "===shownode==="', 'shownode -state';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking nodes");
    $self->{components}->{node} = { name => 'nodes', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'node'));

    return if ($self->{results} !~ /===shownode===.*?\n(.*?)(===|\Z)/msi);
    my @results = split /\n/, $1;

    foreach (@results) {
        next if (!/^\s*(\d+)\s+(\S+)\s+(\S+)/);
        my ($instance, $state, $detail_state) = ($1, $2, $3);

        next if ($self->check_filter(section => 'node', instance => $instance));
        $self->{components}->{node}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("node '%s' state is '%s' [instance: '%s'] [detailed state: %s]",
                                    $instance, $state, $instance, $detail_state)
                                    );
        my $exit = $self->get_severity(label => 'default', section => 'node', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Node '%s' state is '%s'",
                                                             $instance, $state));
        }
    }
}

1;
