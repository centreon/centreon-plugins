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

package storage::hp::3par::ssh::mode::components::psu;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    #Node PS -Assem_Part- -Assem_Serial- ACState DCState PSState
    # 0,1  0   682372-001 5CQLQA1433H0B8 OK      OK      OK     
    # 0,1  1   682372-001 5CQLQA1434W2ED OK      OK      OK     
    # 2,3  0   682372-001 5CQLQA1433Y0KS OK      OK      OK     
    # 2,3  1   682372-001 5CQLQX1XX3E056 OK      OK      OK  
    push @{$self->{commands}}, 'echo "===showpsu==="', 'shownode -ps';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = { name => 'psus', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    return if ($self->{results} !~ /===showpsu===.*?\n(.*?)(===|\Z)/msi);
    my @results = split /\n/, $1;

    foreach (@results) {
        next if (!/^\s*(\S+)\s+(\d+)\s+\S+\s+\S+\s+(\S+)\s+(\S+)\s+(\S+)/);
        my ($instance, $ac_state, $dc_state, $psu_state) = ('node' . $1 . '.psu' . $2, $3, $4, $5);

        next if ($self->check_filter(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("power supply '%s' state is '%s' [instance: '%s'] [ac state: %s] [dc state: %s]",
                                    $instance, $psu_state, $instance, $ac_state, $dc_state)
                                    );
        my $exit = $self->get_severity(label => 'default', section => 'psu', value => $psu_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Power supply '%s' state is '%s'",
                                                             $instance, $psu_state));
        }
    }
}

1;
