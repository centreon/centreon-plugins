#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package centreon::common::emc::navisphere::mode::spcomponents::lcc;

use strict;
use warnings;

sub load { };

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking link control card");
    $self->{components}->{lcc} = {name => 'lccs', total => 0, skip => 0};
    return if ($self->check_filter(section => 'lcc'));
    
    # Bus 1 Enclosure 6 LCC A State: Present
    while ($self->{response} =~ /^Bus\s+(\d+)\s+Enclosure\s+(\d+)\s+LCC\s+(\S+)\s+State:\s+(.*)$/mgi) {
        my $instance = "$1.$2.$3";
        my $state = $4;
        
        next if ($self->check_filter(section => 'lcc', instance => $instance));
        $self->{components}->{lcc}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("lcc '%s' state is %s.",
                                                        $instance, $state)
                                    );
        my $exit = $self->get_severity(section => 'lcc', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("lcc '%s' state is %s",
                                                             $instance, $state));
        }
    }
}

1;