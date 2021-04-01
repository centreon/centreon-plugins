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

package hardware::server::hp::ilo::xmlapi::mode::components::cpu;

use strict;
use warnings;

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cpu");
    $self->{components}->{cpu} = {name => 'cpu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cpu'));
    return if (!defined($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{PROCESSORS}->{PROCESSOR}));

    # STATUS can be missing
    # 
    #<PROCESSORS>
    #      <PROCESSOR>
    #           <LABEL VALUE = "Proc 1"/>
    #           <NAME VALUE = " Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz      "/>
    #           <STATUS VALUE = "OK"/>
    #           <SPEED VALUE = "2500 MHz"/>
    #           <EXECUTION_TECHNOLOGY VALUE = "10/10 cores; 20 threads"/>
    #           <MEMORY_TECHNOLOGY VALUE = "64-bit Capable"/>
    #           <INTERNAL_L1_CACHE VALUE = "320 KB"/>
    #           <INTERNAL_L2_CACHE VALUE = "2560 KB"/>
    #           <INTERNAL_L3_CACHE VALUE = "25600 KB"/>
    #      </PROCESSOR>
    foreach my $result (@{$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{PROCESSORS}->{PROCESSOR}}) {
        next if (!defined($result->{STATUS}));
        my $instance = $result->{LABEL}->{VALUE};
        
        next if ($self->check_filter(section => 'cpu', instance => $instance));
        next if ($result->{STATUS}->{VALUE} =~ /not installed|n\/a|not present|not applicable/i &&
                 $self->absent_problem(section => 'cpu', instance => $instance));

        $self->{components}->{cpu}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("cpu '%s' status is '%s' [instance = %s]",
                                    $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}, $instance));
        
        my $exit = $self->get_severity(label => 'default', section => 'CPU', value => $result->{STATUS}->{VALUE});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("CPU '%s' status is '%s'", $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}));
        }
    }
}

1;