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

package storage::emc::symmetrix::vmax::local::mode::components::director;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

#Directors status: OK
#
#+----------+--------+---------+-------------+---------+-----------------+-------------+
#| Director | Type   | State   | Flags       | Version | Address         | Last Update |
#+----------+--------+---------+-------------+---------+-----------------+-------------+
#| 07A      | DA_4x1 | Online  | [ON] (0x80) | 05      | 192.168.177.7   | 1110        |
#| 07B      | DA_4x1 | Online  | [ON] (0x80) | 05      | 192.168.177.23  | 1110        |
#| 07C      | DA_4x1 | Online  | [ON] (0x80) | 05      | 192.168.177.39  | 1110        |
#| 07D      | DA_4x1 | Online  | [ON] (0x80) | 05      | 192.168.177.55  | 1110        |
#+----------+--------+---------+-------------+---------+-----------------+-------------+
#| Director | Type   | State   | Flags       | Version | Address         | Last Update |
#+----------+--------+---------+-------------+---------+-----------------+-------------+

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking directors");
    $self->{components}->{director} = {name => 'directors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'director'));
    
    if ($self->{content_file_health_env} !~ /Ethernet cabling.*?Directors status.*?---------.*?Director.*?---------.*?\n(.*?\n)\+---------/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find directors');
        return ;
    }
    
    my $content = $1;
    while ($content =~ /^\|(.*?)\|.*?\|(.*?)\|.*?\n/msig) {
        my ($director, $status) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2));

        next if ($self->check_filter(section => 'director', instance => $director));
        $self->{components}->{director}->{total}++;
            
        $self->{output}->output_add(long_msg => sprintf("director '%s' status is '%s'", 
                                                        $director, $status));
        my $exit = $self->get_severity(label => 'default', section => 'director', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Director '%s' status is '%s'", 
                                                             $director, $status));
        }
    }
}

1;
