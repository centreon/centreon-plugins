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

package storage::emc::symmetrix::dmx34::local::mode::components::test;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

#--------------[ Director Tests ]---------------
# 
#  No offline pending DAs are present
#  1C test: All Directors Passed
#  F2,SAME,,,EE test: All Directors Passed
#  EE test: All Directors Passed
sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking test");
    $self->{components}->{test} = {name => 'test', total => 0, skip => 0};
    return if ($self->check_filter(section => 'test'));
    
    if ($self->{content_file_health} !~ /----\[ Director Tests(.*?)----\[/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find tests');
        return ;
    }
    
    my $content = $1;    
    $self->{components}->{test}->{total}++;
    
    foreach (('No offline pending DAs are present', '1C test: All Directors Passed', 
              'F2,SAME,,,EE test: All Directors Passed', 'EE test: All Directors Passed')) {
        if ($content !~ /$_/msi) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("test problem detected"));
        } else {
            $self->{output}->output_add(long_msg => sprintf("%s", $_));
        }
    }
}

1;
