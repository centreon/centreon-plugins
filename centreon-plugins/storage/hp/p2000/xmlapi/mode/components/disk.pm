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

package storage::hp::p2000::xmlapi::mode::components::disk;

use strict;
use warnings;

my @conditions = (
    ['^degraded$' => 'WARNING'],
    ['^failed$' => 'CRITICAL'],
    ['^(unknown|not available)$' => 'UNKNOWN'],
);

my %health = (
    0 => 'ok',
    1 => 'degraded',
    2 => 'failed',
    3 => 'unknown',
    4 => 'not available',
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'disk'));
    
    my $results = $self->{p2000}->get_infos(cmd => 'show disks', 
                                            base_type => 'drives',
                                            key => 'durable-id', 
                                            properties_name => '^health-numeric$');
    
    foreach my $disk_id (keys %$results) {
        next if ($self->check_exclude(section => 'disk', instance => $disk_id));
        $self->{components}->{disk}->{total}++;
        
        my $state = $health{$results->{$disk_id}->{'health-numeric'}};
        
        $self->{output}->output_add(long_msg => sprintf("Disk '%s' status is %s.",
                                                        $disk_id, $state)
                                    );
        foreach (@conditions) {
            if ($state =~ /$$_[0]/i) {
                $self->{output}->output_add(severity =>  $$_[1],
                                            short_msg => sprintf("Disk '%s' status is %s",
                                                        $disk_id, $state));
                last;
            }
        }
    }
}

1;