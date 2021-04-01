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

package storage::emc::symmetrix::dmx34::local::mode::components::config;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

#     ---------[ Configuration Information ]---------
# 
#...
sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking config");
    $self->{components}->{config} = {name => 'config', total => 0, skip => 0};
    return if ($self->check_filter(section => 'config'));
    
    if ($self->{content_file_health} !~ /----\[ Configuration Information(.*?)----\[/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find config');
        return ;
    }
    
    my $content = $1;    
    $self->{components}->{config}->{total}++;
    
    # Error if not present:
    #    CODE OK!
    if ($content !~ /CODE OK!/msi) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("problem of configuration"));
    } else {
        $self->{output}->output_add(long_msg => sprintf("no configuration problem detected"));
    }
}

1;
