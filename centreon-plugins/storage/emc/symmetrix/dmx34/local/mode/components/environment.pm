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

package storage::emc::symmetrix::dmx34::local::mode::components::environment;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

#     -------------[ Power Information ]-------------
# 
#  No Environmental Problems found
sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking environment");
    $self->{components}->{environment} = {name => 'environment', total => 0, skip => 0};
    return if ($self->check_filter(section => 'environment'));
    
    if ($self->{content_file_health} !~ /----\[ Power Information(.*?)----\[/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find environment');
        return ;
    }
    
    my $content = $1;    
    $self->{components}->{environment}->{total}++;
    
    # Error if not present:
    #    No Environmental Problems found
    if ($content !~ /No Environmental Problems found/msi) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("environment problem detected"));
    } else {
        $self->{output}->output_add(long_msg => sprintf("no environment problem detected"));
    }
}

1;
