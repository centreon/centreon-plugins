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

package hardware::server::hp::ilo::xmlapi::mode::components::psu;

use strict;
use warnings;

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    return if (!defined($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{POWER_SUPPLIES}->{SUPPLY}));

    #<POWER_SUPPLIES>
    #      <SUPPLY>
    #           <LABEL VALUE = "Power Supply 1"/>
    #           <PRESENT VALUE = "Yes"/>
    #           <STATUS VALUE = "Good, In Use"/>
    #           <PDS VALUE = "Yes"/>
    #           <HOTPLUG_CAPABLE VALUE = "Yes"/>
    #           <MODEL VALUE = "656362-B21"/>
    #           <SPARE VALUE = "660184-001"/>
    #           <SERIAL_NUMBER VALUE = "5BXRA0D4D6M0FW"/>
    #           <CAPACITY VALUE = "460 Watts"/>
    #           <FIRMWARE_VERSION VALUE = "1.00"/>
    #      </SUPPLY>
    foreach my $result (@{$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{POWER_SUPPLIES}->{SUPPLY}}) {
        my $instance = $result->{LABEL}->{VALUE};
        
        next if ($self->check_filter(section => 'psu', instance => $instance));
        next if ($result->{STATUS}->{VALUE} =~ /not installed|n\/a|not present|not applicable/i &&
                 $self->absent_problem(section => 'psu', instance => $instance));

        $self->{components}->{psu}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("power supply '%s' status is '%s' [instance = %s]",
                                    $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}, $instance));
        
        my $exit = $self->get_severity(label => 'default', section => 'psu', value => $result->{STATUS}->{VALUE});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is '%s'", $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}));
        }
    }
}

1;