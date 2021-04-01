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

package hardware::devices::camera::hanwha::snmp::mode::components::sdcard;

use strict;
use warnings;

my $oid_nwCam = '.1.3.6.1.4.1.36849.1.2';

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sdcard");
    $self->{components}->{sdcard} = { name => 'sdcard', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'sdcard'));

    my $branch_sdcard_status = '4.3.0';

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_nwCam}})) {
        next if ($oid !~ /^$oid_nwCam\.(\d+)\.$branch_sdcard_status$/);

        my $instance = '0';
        my $sdcard_status = $self->{results}->{$oid_nwCam}->{$oid};
        next if ($self->check_filter(section => 'sdcard', instance => $instance));
        
        $self->{components}->{sdcard}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("sdcard '%s' status is '%s' [instance = %s]",
                                                        $instance, $sdcard_status, $instance));
        my $exit = $self->get_severity(section => 'sdcard', instance => $instance, value => $sdcard_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("sdcard '%s' status is '%s'", $instance, $sdcard_status));
        }
    }
}

1;
