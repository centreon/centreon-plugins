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

package storage::emc::celerra::local::mode::components::controlstation;

use strict;
use warnings;

my %map_cs_status = (
    6 => 'Control Station is ready, but is not running NAS service',
    10 => 'Primary Control Station',
    11 => 'Secondary Control Station',
);

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking control stations");
    $self->{components}->{controlstation} = {name => 'control stations', total => 0, skip => 0};
    return if ($self->check_filter(section => 'controlstation'));

    foreach my $line (split /\n/, $self->{stdout}) {
        next if ($line !~ /^\s*(\d+)\s+-\s+(\S+)/);
        my ($code, $instance) = ($1, $2);
        next if (!defined($map_cs_status{$code}));
        
        return if ($self->check_filter(section => 'controlstation', instance => $instance));
        
        $self->{components}->{controlstation}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Control station '%s' status is '%s'",
                                    $instance, $map_cs_status{$code}));
        my $exit = $self->get_severity(section => 'controlstation', instance => $instance, value => $map_cs_status{$code});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Control station '%s' status is '%s'",
                                                             $instance, $map_cs_status{$code}));
        }
    }
}

1;