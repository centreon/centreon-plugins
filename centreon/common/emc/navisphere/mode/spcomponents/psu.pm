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

package centreon::common::emc::navisphere::mode::spcomponents::psu;

use strict;
use warnings;

sub load { };

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    
    # Enclosure SPE Power A0 State: Present
    # Bus 0 Enclosure 0 Power A State: Present
    while ($self->{response} =~ /^(?:Bus\s+(\d+)\s+){0,1}Enclosure\s+(\S+)\s+(Power)\s+(\S+)\s+State:\s+(.*)$/mgi) {
        my ($state, $instance) = ($5, "$2.$3.$4");
        if (defined($1)) {
            $instance = "$1.$2.$3.$4";
        }
        
        next if ($self->check_filter(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Power Supply '%s' state is %s.",
                                                        $instance, $state)
                                    );
        my $exit = $self->get_severity(section => 'psu', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power Supply '%s' state is %s",
                                                             $instance, $state));
        }
    }
}

1;