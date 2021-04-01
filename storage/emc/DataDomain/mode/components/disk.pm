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

package storage::emc::DataDomain::mode::components::disk;

use strict;
use warnings;
use centreon::plugins::misc;

my $oid_diskPropState;

my %map_disk_status = (
    1 => 'ok',
    2 => 'unknown',
    3 => 'absent',
    4 => 'failed',
    5 => 'spare',     # since OS 5.4
    6 => 'available', # since OS 5.4
    8 => 'raidReconstruction', # since OS 7.x
    9 => 'copyReconstruction', # since OS 7.x 
    10 => 'system',            # since OS 7.x
);

sub load {
    my ($self) = @_;
    
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_diskPropState = '.1.3.6.1.4.1.19746.1.6.1.1.1.8';
    } else {
        $oid_diskPropState = '.1.3.6.1.4.1.19746.1.6.1.1.1.7';
    }
    push @{$self->{request}}, { oid => $oid_diskPropState };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_diskPropState}})) {
        $oid =~ /^$oid_diskPropState\.(.*)$/;
        my $instance = $1;
        my $disk_status = defined($map_disk_status{$self->{results}->{$oid_diskPropState}->{$oid}}) ?
                            $map_disk_status{$self->{results}->{$oid_diskPropState}->{$oid}} : 'unknown';

        next if ($self->check_filter(section => 'disk', instance => $instance));
        next if ($disk_status =~ /absent/i && 
                 $self->absent_problem(section => 'disk', instance => $instance));
        
        $self->{components}->{disk}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Disk '%s' status is '%s'",
                                    $instance, $disk_status));
        my $exit = $self->get_severity(section => 'disk', value => $disk_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' status is '%s'", $instance, $disk_status));
        }
    }
}

1;
