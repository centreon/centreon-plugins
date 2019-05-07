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

package centreon::common::emc::navisphere::mode::spcomponents::cable;

use strict;
use warnings;

sub load { };

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cables");
    $self->{components}->{cable} = {name => 'cables', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cable'));
    
    # Enclosure SPE SPS A Cabling State: Valid
    while ($self->{response} =~ /^(?:Bus\s+(\d+)\s+){0,1}Enclosure\s+(\S+)\s+(Power|SPS)\s+(\S+)\s+Cabling\s+State:\s+(.*)$/mgi) {
        my ($state, $instance) = ($5, "$2.$3.$4");
        if (defined($1)) {
            $instance = "$1.$2.$3.$4";
        }
        
        next if ($self->check_filter(section => 'cable', instance => $instance));
        $self->{components}->{cable}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("cable '%s' state is %s.",
                                                        $instance, $state)
                                    );
        my $exit = $self->get_severity(section => 'cable', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("cable '%s' state is %s",
                                                             $instance, $state));
        }
    }
}

1;