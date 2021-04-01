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

package storage::emc::symmetrix::vmax::local::mode::components::power;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

#Power system: OK
#
#+--------------------------------------------------------+--------------------------------------+
#| Item                                                   | Status                               |
#+--------------------------------------------------------+--------------------------------------+
#| Power input type                                       | Three Phases                         |
#| System Bay AC Zones Status                             | OK                                   |
#|   AC Status Zone A                                     | Zone AC OK                           |
#|   AC Status Zone B                                     | Zone AC OK                           |
#| Power modules status                                   | OK                                   |
#|   System Bay 1                                         | OK                                   |
#|     Engine SPS 4A                                      | OK                                   |
#|       General Status                                   | OK                                   |
#|       Detailed Status                                  | OK                                   |
#|       Condition Register                               | OK                                   |
#|       Battery Life (sec)                               | 600                                  |
#|       Days of Operation                                | Unknown                              |
#|       Slot                                             | Slot B                               |
#|       Manufacturer Information                         | ASTEC,AA23540,7E,  04/11/2008        |
#+--------------------------------------------------------+--------------------------------------+
#| Item                                                   | Status                               |
#+--------------------------------------------------------+--------------------------------------+

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking powers");
    $self->{components}->{power} = {name => 'powers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'power'));
    
    if ($self->{content_file_health_env} !~ /Ethernet cabling.*?Power system.*?---------.*?Item.*?---------.*?\n(.*?\n)\+---------/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find powers');
        return ;
    }
    
    my $content = $1;
    
    my $total_components = 0;
    my @stack = ({ indent => 0, long_instance => '' });
    while ($content =~ /^\|([ \t]+)(.*?)\|(.*?)\|\n/msig) {
        my ($indent, $name, $status) = (length($1), centreon::plugins::misc::trim($2), centreon::plugins::misc::trim($3));
        
        pop @stack while ($indent <= $stack[$#stack]->{indent});
        
        my $long_instance = $stack[$#stack]->{long_instance} . '>' . $name;
        if ($indent > $stack[$#stack]->{indent}) {
            push @stack, { indent => $indent, 
                           long_instance => $stack[$#stack]->{long_instance} . '>' . $name };
        }
        
        next if ($name !~ /status/i);
        
        next if ($self->check_filter(section => 'power', instance => $long_instance));
        $self->{components}->{power}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("power '%s' status is '%s'", 
                                                        $long_instance, $status));
        my $exit = $self->get_severity(label => 'default', section => 'power', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power '%s' status is '%s'", 
                                                             $long_instance, $status));
        }
    }
}

1;
