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

package storage::emc::symmetrix::dmx34::local::mode::components::director;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

#     ---------------[ Director Status ]-------------
# 
#     01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16
# 
# D   ON .. .. .. .. .. .. ON ON .. .. .. .. .. .. ON
# C   ON .. .. .. .. .. .. ON ON .. .. .. .. .. .. ON
# B   ON .. .. .. .. .. .. DD ON .. .. .. .. .. .. ON
# A   ON .. .. .. .. .. .. ON ON .. .. .. .. .. .. ON
# 
# Key:
#  ON - Director is online
#  OF - Director is offline
#  OF - DA is offline
#  DD - Director is in DD state
#  PR - Director is in Probe mode
#  NC - Director is not comunicating
#  ** - Director status is unknown

my %mapping = (
    DD => 'DD state',
    PR => 'Probe mode',
    NC => 'not comunicating',
    '**' => 'unknown',,
    OF => 'offline',
    ON => 'online',,
    '..' => 'not configured',
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking directors");
    $self->{components}->{director} = {name => 'directors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'director'));
    
    if ($self->{content_file_health} !~ /---------------\[ Director Status(.*?)----\[/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find directors');
        return ;
    }
    
    my $content = $1;
    while ($content =~ /\s([A-Z]\s+.*?)\n/msig) {
        my ($director, @nums) = split /\s+/, $1;
        my $i = 0;
        foreach (@nums) {
            $i++;
            my $state = defined($mapping{$_}) ? $mapping{$_} : 'unknown';
            my $instance = $director . '.' . $i;
            
            next if ($self->check_filter(section => 'director', instance => $instance));
            $self->{components}->{director}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("director '%s' state is '%s'", 
                                                            $instance, $state));
            my $exit = $self->get_severity(section => 'director', value => $state);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Director '%s' state is '%s'", 
                                                                 $instance, $state));
            }
        }
    }
}

1;
