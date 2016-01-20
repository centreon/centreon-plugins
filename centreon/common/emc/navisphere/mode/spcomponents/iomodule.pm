#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package centreon::common::emc::navisphere::mode::spcomponents::iomodule;

use strict;
use warnings;

my @conditions = (
    ['^(?!(Present|Valid|Empty)$)' => 'CRITICAL'],
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking I/O modules");
    $self->{components}->{io} = {name => 'IO module', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'io'));
    
    # Enclosure SPE SP A I/O Module 0 State: Present
    while ($self->{response} =~ /^Enclosure\s+(\S+)\s+SP\s+(\S+)\s+I\/O\s+Module\s+(\S+)\s+State:\s+(.*)$/mgi) {
        my $instance = "$1.$2.$3";
        my $state = $4;
        
        next if ($self->check_exclude(section => 'io', instance => $instance));
        $self->{components}->{io}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("I/O module '%s' state is %s.",
                                                        $instance, $state)
                                    );
        foreach (@conditions) {
            if ($state =~ /$$_[0]/i) {
                $self->{output}->output_add(severity =>  $$_[1],
                                            short_msg => sprintf("I/O module '%s' state is %s",
                                                        $instance, $state));
                last;
            }
        }
    }
}

1;