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

package hardware::server::hp::ilo::xmlapi::mode::components::ldrive;

use strict;
use warnings;

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking logical drives");
    $self->{components}->{ldrive} = {name => 'ldrive', total => 0, skip => 0};
    return if ($self->check_filter(section => 'ldrive'));

    return if (!defined($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{STORAGE}->{CONTROLLER}));

    #<STORAGE>
    #      <CONTROLLER>
    #           ...
    #           <LOGICAL_DRIVE>
    #                <LABEL VALUE = "01"/>
    #                <STATUS VALUE = "OK"/>
    #                <CAPACITY VALUE = "419 GB"/>
    #                <FAULT_TOLERANCE VALUE = "RAID 1/RAID 1+0"/>
    #                <ENCRYPTION_STATUS VALUE = "Not Encrypted"/>
    #               
    #
    foreach my $ctrl (@{$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{STORAGE}->{CONTROLLER}}) {
        next if (!defined($ctrl->{LOGICAL_DRIVE}));
        
        foreach my $result (@{$ctrl->{LOGICAL_DRIVE}}) {
            my $instance = $result->{LABEL}->{VALUE};
            
            next if ($self->check_filter(section => 'ldrive', instance => $instance));
            next if ($result->{STATUS}->{VALUE} =~ /not installed|n\/a|not present|not applicable/i &&
                     $self->absent_problem(section => 'ldrive', instance => $instance));

            $self->{components}->{ldrive}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("logical drive '%s' status is '%s' [instance = %s]",
                                        $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}, $instance));
            
            my $exit = $self->get_severity(label => 'default', section => 'ldrive', value => $result->{STATUS}->{VALUE});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Logical drive '%s' status is '%s'", $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}));
            }
        }
    }
}

1;