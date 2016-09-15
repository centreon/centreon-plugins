#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::globalstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    0 => ['non recoverable', 'CRITICAL'], 
    2 => ['critical', 'CRITICAL'], 
    4 => ['non critical', 'WARNING'], 
    255 => ['nominal', 'OK'],
);

sub check {
    my ($self) = @_;

    my $oid_systemHealthStat = '.1.3.6.1.4.1.2.3.51.3.1.4.1.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_systemHealthStat], nothing_quit => 1);
    
    $self->{components}->{global} = {name => 'system health', total => 1};
    $self->{output}->output_add(long_msg => sprintf("System health status is '%s'.", 
                                                    ${$states{$result->{$oid_systemHealthStat}}}[0]));
    if (${$states{$result->{$oid_systemHealthStat}}}[1] ne 'OK') {
        $self->{output}->output_add(severity =>  ${$states{$result->{$oid_systemHealthStat}}}[1],
                                    short_msg => sprintf("System health status is '%s'.", 
                                                         ${$states{$result->{$oid_systemHealthStat}}}[0]));
    }
}

1;