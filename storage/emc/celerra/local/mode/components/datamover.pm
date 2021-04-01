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

package storage::emc::celerra::local::mode::components::datamover;

use strict;
use warnings;

my %map_dm_status = (
    0 => 'Reset (or unknown state)',
    1 => 'DOS boot phase, BIOS check, boot sequence',
    2 => 'SIB POST failures (that is, hardware failures)',
    3 => 'DART is loaded on Data Mover, DOS boot and execution of boot.bat, boot.cfg',
    4 => 'DART is ready on Data Mover, running, and MAC threads started',
    5 => 'DART is in contact with Control Station box monitor',
    7 => 'DART is in panic state',
    9 => 'DART reboot is pending or in halted state',
    13 => 'DART panicked and completed memory dump',
    14 => 'DM Misc problems',
    15 => 'Data Mover is flashing firmware. DART is flashing BIOS and/or POST firmware. Data Mover cannot be reset',
    17 => 'Data Mover Hardware fault detected',
    18 => 'DM Memory Test Failure. BIOS detected memory error',
    19 => 'DM POST Test Failure. General POST error',
    20 => 'DM POST NVRAM test failure. Invalid NVRAM content error',
    21 => 'DM POST invalid peer Data Mover type',
    22 => 'DM POST invalid Data Mover part number',
    23 => 'DM POST Fibre Channel test failure. Error in blade Fibre connection',
    24 => 'DM POST network test failure. Error in Ethernet controller',
    25 => 'DM T2NET Error. Unable to get blade reason code due to management switch problems',
);

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking data movers");
    $self->{components}->{datamover} = {name => 'data movers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'datamover'));

    foreach my $line (split /\n/, $self->{stdout}) {
        next if ($line !~ /^\s*(\d+)\s+-\s+(\S+)/);
        my ($code, $instance) = ($1, $2);
        next if (!defined($map_dm_status{$code}));
        
        return if ($self->check_filter(section => 'datamover', instance => $instance));
        
        $self->{components}->{datamover}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Data mover '%s' status is '%s'",
                                    $instance, $map_dm_status{$code}));
        my $exit = $self->get_severity(section => 'datamover', instance => $instance, value => $map_dm_status{$code});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Data mover '%s' status is '%s'",
                                                             $instance, $map_dm_status{$code}));
        }
    }
}

1;