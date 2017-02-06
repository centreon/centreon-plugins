#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package os::solaris::local::mode::lomv120components::fan;

use strict;
use warnings;

my %conditions = (
    1 => ['^(?!(OK)$)' => 'CRITICAL'],
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));
    
    #Fans:
    #1 FAULT speed 0%
    #2 FAULT speed 0%
    #3 OK speed 100%
    #4 OK speed 100%
    return if ($self->{stdout} !~ /^Fans:(.*?):/ims);
    
    my @content = split(/\n/, $1);
    shift @content;
    pop @content;
    foreach my $line (@content) {
        next if ($line !~ /^\s*(\S+)\s+(\S+)/);
        my ($instance, $status) = ($1, $2);
        
        next if ($self->check_exclude(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is %s.",
                                                        $instance, $status)
                                    );
        foreach (keys %conditions) {
            if ($status =~ /${$conditions{$_}}[0]/i) {
                $self->{output}->output_add(severity => ${$conditions{$_}}[1],
                                            short_msg => sprintf("fan '%s' status is %s",
                                                                 $instance, $status));
                last;
            }
        }
    }
}

1;