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

package hardware::server::sun::mgmt_cards::components::showenvironment::si;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking system indicator");
    $self->{components}->{si} = {name => 'system indicator', total => 0, skip => 0};
    return if ($self->check_filter(section => 'si'));
    
    #--------------------------------------------------------
    #System Indicator Status:
    #--------------------------------------------------------
    #MB.LOCATE            MB.SERVICE           MB.ACT
    #--------------------------------------------------------
    #OFF                  OFF                  ON
    
    #--------------------------------------------------------
    #System Indicator Status:
    #--------------------------------------------------------
    #SYS/LOCATE           SYS/SERVICE          SYS/ACT
    #OFF                  OFF                  ON
    #--------------------------------------------------------
    #SYS/REAR_FAULT       SYS/TEMP_FAULT       SYS/TOP_FAN_FAULT
    #OFF                  OFF                  OFF
    #--------------------------------------------------------
    
    if ($self->{stdout} =~ /^System Indicator Status.*?\n(.*?)\n\n/ims && defined($1)) {
        my $match = $1;

        if ($match =~ /^.*(MB\.SERVICE).*?\n---+\n\s*\S+\s*(\S+)/ims || 
            $match =~ /^.*(SYS\/SERVICE).*?\n\s*\S+\s*(\S+)/ims) {
            my $si_name = defined($1) ? $1 : 'unknown';
            my $si_status = defined($2) ? $2 : 'unknown';
            
            next if ($self->check_filter(section => 'si', instance => $si_name));
            
            $self->{components}->{si}->{total}++;
            $self->{output}->output_add(long_msg => "System Indicator Status '$si_name' is " . $si_status);
            my $exit = $self->get_severity(section => 'si', value => $si_status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => "System Indicator Status '$si_name' is " . $si_status);
            }
        }
    }
}

1;
