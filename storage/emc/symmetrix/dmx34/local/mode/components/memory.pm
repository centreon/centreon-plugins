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

package storage::emc::symmetrix::dmx34::local::mode::components::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

#------------[ Memory Information ]-------------
# 
#  Memory Size:      80 GB
#  Cache start Addr: 00088000 (Hex)
#  Cache start Bank: 00000022 (Hex)
#  Cache last Addr:  01400000 (Hex)
#  Cache last Bank:  000004FF (Hex)
# 
#  Board Number  M0      M1      M2      M3      M4      M5      M6      M7
#  Slot Number   10      11      12      13      14      15      16      17
#                ----------------------------------------------------------
#  Size (GB)     16      16      16      16       8       8      ..      ..
#  Mode          OPER    OPER    OPER    OPER    OPER    OPER    ..      ..
#  Status        OK      OK      OK      OK      OK      OK      ..      ..
# 
#  Status Key
#    OK      - Board is operating normally

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking memory");
    $self->{components}->{memory} = {name => 'memory', total => 0, skip => 0};
    return if ($self->check_filter(section => 'memory'));
    
    if ($self->{content_file_health} !~ /----\[ Memory Information(.*?)----\[/msi) {
        $self->{output}->output_add(long_msg => 'skipping: cannot find memory');
        return ;
    }
    
    my $content = $1;
    
    $content =~ /Board Number\s+(.*?)\n/msi;
    my @board_numbers = split /\s+/, $1;
    
    $content =~ /Slot Number\s+(.*?)\n/msi;
    my @slot_numbers = split /\s+/, $1;
    
    $content =~ /Mode\s+(.*?)\n/msi;
    my @modes = split /\s+/, $1;
    
    $content =~ /Status\s+(.*?)\n/msi;
    my @status = split /\s+/, $1;
    
    my $i = -1;
    foreach my $name (@board_numbers) {
        $i++;
        my $instance = $name . '#' . $slot_numbers[$i];
        my $state = $modes[$i] . '/' . $status[$i];
        
        next if ($self->check_filter(section => 'memory', instance => $instance));
        $self->{components}->{memory}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("memory '%s' state is '%s'", 
                                                        $instance, $state));
        my $exit = $self->get_severity(section => 'memory', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Memory '%s' state is '%s'", 
                                                             $instance, $state));
        }
    }
}

1;
