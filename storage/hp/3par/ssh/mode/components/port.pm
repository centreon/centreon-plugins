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

package storage::hp::3par::ssh::mode::components::port;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    #N:S:P      Mode   State ----Node_WWN---- -Port_WWN/HW_Addr- Type Protocol Label Partner FailoverState
    #0:0:1 initiator   ready 50002ACFF70047C0   50002AC0010047C0 disk      SAS  DP-1       -             -
    #0:0:2 initiator   ready 50002ACFF70047C0   50002AC0020047C0 disk      SAS  DP-2       -             -
    #0:1:1    target   ready 2FF70002AC0047C0   20110002AC0047C0 host       FC     -   1:1:1          none
    #0:1:2    target   ready 2FF70002AC0047C0   20120002AC0047C0 host       FC     -   1:1:2          none
    #0:2:1 initiator   ready 2FF70002AC0047C0   20210002AC0047C0 rcfc       FC     -       -             -
    #0:2:2    target   ready 2FF70002AC0047C0   20220002AC0047C0 host       FC     -       -             -
    #0:2:3    target   ready 2FF70002AC0047C0   20230002AC0047C0 host       FC     -   1:2:3          none
    #0:2:4    target   ready 2FF70002AC0047C0   20240002AC0047C0 host       FC     -   1:2:4          none
    #0:3:1      peer offline                -       B4B52FA71D43 free       IP   IP0       -             -
    #1:0:1 initiator   ready 50002ACFF70047C0   50002AC1010047C0 disk      SAS  DP-1       -             -
    #1:0:2 initiator   ready 50002ACFF70047C0   50002AC1020047C0 disk      SAS  DP-2       -             -
    push @{$self->{commands}}, 'echo "===showport==="', 'showport';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking ports");
    $self->{components}->{port} = { name => 'ports', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'port'));

    return if ($self->{results} !~ /===showport===.*?\n(.*?)(===|\Z)/msi);
    my @results = split /\n/, $1;

    foreach (@results) {
        next if (!/^(\d+:\d+:\d+)\s+\S+\s+(\S+)\s+\S+\s+\S+\s+(\S+)/);
        my ($nsp, $state, $type) = ($1, $2, $3);
        my $instance = $type . '.' . $nsp;

        next if ($self->check_filter(section => 'port', instance => $instance));
        $self->{components}->{port}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("port '%s' state is '%s' [instance: '%s']",
                                    $nsp, $state, $instance)
                                    );
        my $exit = $self->get_severity(section => 'port', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("port '%s' state is '%s'",
                                                             $nsp, $state));
        }
    }
}

1;
