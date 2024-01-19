#
# Copyright 2024 Centreon (http://www.centreon.com/)
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
use storage::hp::p2000::xmlapi::mode::components::resources qw($map_health);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = { name => 'disks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));
    
    my ($results) = $self->{custom}->get_infos(
        cmd => 'show disks', 
        base_type => 'drives',
        key => 'durable-id', 
        properties_name => '^health-numeric$',
        no_quit => 1
    );

    foreach my $disk_id (keys %$results) {
        next if ($self->check_filter(section => 'disk', instance => $disk_id));
        $self->{components}->{disk}->{total}++;
        
        my $state = $map_health->{$results->{$disk_id}->{'health-numeric'}};
        
        $self->{output}->output_add(
            long_msg => sprintf(
                "disk '%s' status is %s [instance: %s]",
                $disk_id, $state, $disk_id
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'disk', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Disk '%s' status is '%s'", $disk_id, $state)
            );
        }
    }
}

1;
