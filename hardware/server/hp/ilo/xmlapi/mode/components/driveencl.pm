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

package hardware::server::hp::ilo::xmlapi::mode::components::driveencl;

use strict;
use warnings;

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking drive enclosures");
    $self->{components}->{driveencl} = {name => 'driveencl', total => 0, skip => 0};
    return if ($self->check_filter(section => 'driveencl'));
    return if (!defined($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{STORAGE}->{CONTROLLER}));

    #<STORAGE>
    #      <CONTROLLER>
    #           ...
    #           <DRIVE_ENCLOSURE>
    #               <LABEL VALUE = "Port 1I Box 1"/>
    #               <STATUS VALUE = "OK"/>
    #               <DRIVE_BAY VALUE = "04"/>
    #           </DRIVE_ENCLOSURE>
    #
    foreach my $ctrl (@{$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{STORAGE}->{CONTROLLER}}) {
        next if (!defined($ctrl->{DRIVE_ENCLOSURE}));
        
        foreach my $result (@{$ctrl->{DRIVE_ENCLOSURE}}) {
            my $instance = $result->{LABEL}->{VALUE};
            
            next if ($self->check_filter(section => 'driveencl', instance => $instance));
            next if ($result->{STATUS}->{VALUE} =~ /not installed|n\/a|not present|not applicable/i &&
                     $self->absent_problem(section => 'driveencl', instance => $instance));

            $self->{components}->{driveencl}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("drive enclosure '%s' status is '%s' [instance = %s]",
                                        $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}, $instance));
            
            my $exit = $self->get_severity(label => 'default', section => 'driveencl', value => $result->{STATUS}->{VALUE});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Drive enclosure '%s' status is '%s'", $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}));
            }
        }
    }
}

1;