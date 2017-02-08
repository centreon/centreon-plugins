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

package os::solaris::local::mode::lomv120components::voltage;

use strict;
use warnings;
use centreon::plugins::misc;

my %conditions = (
    1 => ['^(?!(ok)$)' => 'CRITICAL'],
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking supply voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'voltage'));
    
    #Supply voltages:
    #1               5V status=ok
    #2              3V3 status=ok
    #3             +12V status=ok
    return if ($self->{stdout} !~ /^Supply voltages:(((.*?)(?::|Status flag))|(.*))/ims);
    
    my @content = split(/\n/, $1);
    shift @content;
    foreach my $line (@content) {
        $line = centreon::plugins::misc::trim($line);
        next if ($line !~ /^\s*(\S+).*?status=(.*)/);
        my ($instance, $status) = ($1, $2);
        
        next if ($self->check_exclude(section => 'voltage', instance => $instance));
        $self->{components}->{voltage}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Supply voltage '%s' status is %s.",
                                                        $instance, $status)
                                    );
        foreach (keys %conditions) {
            if ($status =~ /${$conditions{$_}}[0]/i) {
                $self->{output}->output_add(severity => ${$conditions{$_}}[1],
                                            short_msg => sprintf("Supply voltage '%s' status is %s",
                                                                 $instance, $status));
                last;
            }
        }
    }
}

1;