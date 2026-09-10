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

package storage::veritas::nba::ssh::mode::components::disk;

use strict;
use warnings;
use centreon::plugins::misc;

sub load {}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking disks');
    $self->{components}->{disk} = { name => 'disk', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));

    while ($self->{result} =~ /Hardware\s+monitor\s+information\s+(.*?)(?=\s+Hardware monitor information|\Z$)/msg) {
        my $part = $1;

        next if ($part !~ /NetBackup\s+StorageShelf\s+(\d+)/i);
        my $shelf = $1;
  
        while ($part =~ /^.*?Controller.*?Disk.*?\|(.*?)\|.*?\|.*?\|.*?\|.*?\|.*?\|.*?\|.*?\|(.*?)\|(.*?)\|/mig) { 
            my ($enclosure, $disk, $state) = (centreon::plugins::misc::trim($2), centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($3));
            my $instance = 'shelf' . $shelf . '.' . $enclosure . '.' . $disk;

            next if ($self->check_filter(section => 'disk', instance => $instance));
            $self->{components}->{disk}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "disk '%s' shelf '%s' enclosure '%s' state is %s",
                    $disk,
                    $shelf,
                    $enclosure,
                    $state
                )
            );
            my $exit = $self->get_severity(label => 'default', section => 'disk', instance => $instance, value => $state);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity =>  $exit,
                    short_msg => sprintf(
                        "disk '%s' shelf '%s' enclosure '%s' state is %s",
                        $disk, $shelf, $enclosure, $state
                    )
                );
            }
        }
    }
}

1;
