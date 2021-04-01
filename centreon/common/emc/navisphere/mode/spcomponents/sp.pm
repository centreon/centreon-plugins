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

package centreon::common::emc::navisphere::mode::spcomponents::sp;

use strict;
use warnings;

sub load { };

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sp");
    $self->{components}->{sp} = {name => 'sp', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sp'));
    
    # SP A State:                 Present
    while ($self->{response} =~ /^SP\s+(\S+)\s+State:\s+(.*)$/mgi) {
        my $instance = $1;
        my $state = $2;
        
        next if ($self->check_filter(section => 'sp', instance => $instance));
        $self->{components}->{sp}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("sp '%s' state is %s.",
                                                        $instance, $state)
                                    );
        my $exit = $self->get_severity(section => 'sp', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("sp '%s' state is %s",
                                                             $instance, $state));
        }
    }
}

1;