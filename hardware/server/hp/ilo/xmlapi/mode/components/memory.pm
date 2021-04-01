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

package hardware::server::hp::ilo::xmlapi::mode::components::memory;

use strict;
use warnings;

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking memories");
    $self->{components}->{memory} = {name => 'memory', total => 0, skip => 0};
    return if ($self->check_filter(section => 'memory'));
    return if (!defined($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{MEMORY}->{MEMORY_DETAILS}));

    #<MEMORY>
    #      <MEMORY_DETAILS>
    #           <CPU_1>
    #                <SOCKET VALUE = "1"/>
    #                <STATUS VALUE = "Good, In Use"/>
    #                <HP_SMART_MEMORY VALUE = "Yes"/>
    #                <PART NUMBER = "712383-081"/>
    #                <TYPE VALUE = "DIMM DDR3"/>
    #                <SIZE VALUE = "16384 MB"/>
    #                <FREQUENCY VALUE = "1866 MHz"/>
    #                <MINIMUM_VOLTAGE VALUE = "1.50 v"/>
    #                <RANKS VALUE = "2"/>
    #                <TECHNOLOGY VALUE = "RDIMM"/>
    #           </CPU_1>
    foreach my $cpu_name (sort keys %{$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{MEMORY}->{MEMORY_DETAILS}}) {
        $self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{MEMORY}->{MEMORY_DETAILS}->{$cpu_name} = [$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{MEMORY}->{MEMORY_DETAILS}->{$cpu_name}]
            if (ref($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{MEMORY}->{MEMORY_DETAILS}->{$cpu_name}) ne 'ARRAY');
        foreach my $result (@{$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{MEMORY}->{MEMORY_DETAILS}->{$cpu_name}}) {
            my $instance = lc($cpu_name) . '.' . $result->{SOCKET}->{VALUE};
            
            next if ($self->check_filter(section => 'memory', instance => $instance));
            next if ($result->{STATUS}->{VALUE} =~ /not installed|n\/a|not present|not applicable/i &&
                     $self->absent_problem(section => 'memory', instance => $instance));

            $self->{components}->{memory}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("memory '%s' status is '%s' [instance = %s]",
                                        $instance, $result->{STATUS}->{VALUE}, $instance));
            
            my $exit = $self->get_severity(label => 'default', section => 'memory', value => $result->{STATUS}->{VALUE});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Memory '%s' status is '%s'", $instance, $result->{STATUS}->{VALUE}));
            }
        }
    }
}

1;