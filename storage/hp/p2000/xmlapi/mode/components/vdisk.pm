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

package storage::hp::p2000::xmlapi::mode::components::vdisk;

use strict;
use warnings;

my %health = (
    0 => 'ok',
    1 => 'degraded',
    2 => 'failed',
    3 => 'unknown',
    4 => 'not available',
);

sub check_vdisk {
    my ($self, %options) = @_;

    foreach my $vdisk_id (keys %{$options{results}}) {
        next if ($self->check_filter(section => 'vdisk', instance => $vdisk_id));
        $self->{components}->{vdisk}->{total}++;
        
        my $state = $health{$options{results}->{$vdisk_id}->{'health-numeric'}};
        
        $self->{output}->output_add(
            long_msg => sprintf(
                "vdisk '%s' status is %s [instance: %s]",
                $vdisk_id, $state, $vdisk_id
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'vdisk', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Vdisk '%s' status is '%s'", $vdisk_id, $state)
            );
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking vdisks");
    $self->{components}->{vdisk} = { name => 'vdisks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'vdisk'));
    
    my ($results, $code) = $self->{custom}->get_infos(
        cmd => 'show vdisks', 
        base_type => 'virtual-disks',
        key => 'name', 
        properties_name => '^health-numeric$',
        no_quit => 1
    );
    if ($code == 0) {
        ($results) = $self->{custom}->get_infos(
            cmd => 'show disk-groups', 
            base_type => 'disk-groups',
            key => 'name', 
            properties_name => '^health-numeric$',
            no_quit => 1
        );
    }

    check_vdisk($self, results => $results);
}

1;
