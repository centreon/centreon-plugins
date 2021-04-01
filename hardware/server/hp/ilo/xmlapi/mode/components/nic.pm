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

package hardware::server::hp::ilo::xmlapi::mode::components::nic;

use strict;
use warnings;

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking nic");
    $self->{components}->{nic} = {name => 'nic', total => 0, skip => 0};
    return if ($self->check_filter(section => 'nic'));
    return if (!defined($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{NIC_INFORMATION}->{NIC}));

    #<NIC_INFORMATION>
    #      <NIC>
    #           <NETWORK_PORT VALUE = "Port 1"/>
    #           <PORT_DESCRIPTION VALUE = "HP Ethernet 1Gb 4-port 331FLR Adapter #4"/>
    #           <LOCATION VALUE = "Embedded"/>
    #           <MAC_ADDRESS VALUE = "a0:d3:c1:f3:47:c3"/>
    #           <IP_ADDRESS VALUE = "N/A"/>
    #           <STATUS VALUE = "OK"/>
    #      </NIC>
   foreach my $result (@{$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{NIC_INFORMATION}->{NIC}}) {
        my $instance = $result->{NETWORK_PORT}->{VALUE};
        $instance = $result->{PORT_DESCRIPTION}->{VALUE} . '.' . $instance
            if (defined($result->{PORT_DESCRIPTION}->{VALUE}));
            
        next if ($self->check_filter(section => 'nic', instance => $instance));
        next if ($result->{STATUS}->{VALUE} =~ /not installed|n\/a|not present|not applicable/i &&
                 $self->absent_problem(section => 'nic', instance => $instance));

        $self->{components}->{nic}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("nic '%s' status is '%s' [instance = %s]",
                                    $instance, $result->{STATUS}->{VALUE}, $instance));
        
        my $exit = $self->get_severity(section => 'nic', value => $result->{STATUS}->{VALUE});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("NIC '%s' status is '%s'", $instance, $result->{STATUS}->{VALUE}));
        }
    }
}

1;
