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

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::fan;

use strict;
use warnings;
use centreon::plugins::misc;

sub check {
    my ($self) = @_;

    $self->{components}->{fans} = {name => 'fans', total => 0};
    $self->{output}->output_add(long_msg => "Checking fans");
    return if ($self->check_exclude('fans'));
    
    my $oid_fanEntry = '.1.3.6.1.4.1.2.3.51.3.1.3.2.1';
    my $oid_fanDescr = '.1.3.6.1.4.1.2.3.51.3.1.3.2.1.2';
    my $oid_fanSpeed = '.1.3.6.1.4.1.2.3.51.3.1.3.2.1.3';
    
    my $result = $self->{snmp}->get_table(oid => $oid_fanEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_fanDescr\.(\d+)$/);
        my $instance = $1;
    
        my $fan_descr = centreon::plugins::misc::trim($result->{$oid_fanDescr . '.' . $instance});
        my $fan_speed = centreon::plugins::misc::trim($result->{$oid_fanSpeed . '.' . $instance});

        $self->{components}->{fans}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' speed is %s.", 
                                    $fan_descr, $fan_speed));
        if ($fan_speed =~ /offline/i) {
            $self->{output}->output_add(severity =>  'WARNING',
                                        short_msg => sprintf("Fan '%s' is offline", $fan_descr));
        } else {
            $fan_speed =~ /(\d+)/;
            $self->{output}->perfdata_add(label => 'fan_' . $fan_descr, unit => '%',
                                          value => $1,
                                          min => 0, max => 100);
        }
    }
}

1;