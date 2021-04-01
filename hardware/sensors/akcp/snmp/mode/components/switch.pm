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

package hardware::sensors::akcp::snmp::mode::components::switch;

use strict;
use warnings;
use hardware::sensors::akcp::snmp::mode::components::resources qw(%map_default2_status %map_online);

my $mapping = {
    hhmsSensorArraySwitchDescription  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.18.1.1' },
    hhmsSensorArraySwitchStatus       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.18.1.3', map => \%map_default2_status },
    hhmsSensorArraySwitchOnline       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.18.1.4', map => \%map_online },
};
my $oid_hhmsSensorArraySwitchEntry = '.1.3.6.1.4.1.3854.1.2.2.1.18.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hhmsSensorArraySwitchEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking switches");
    $self->{components}->{switch} = {name => 'switches', total => 0, skip => 0};
    return if ($self->check_filter(section => 'switch'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_hhmsSensorArraySwitchEntry}})) {
        next if ($oid !~ /^$mapping->{hhmsSensorArraySwitchOnline}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hhmsSensorArraySwitchEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'switch', instance => $instance));
        if ($result->{hhmsSensorArraySwitchOnline} eq 'offline') {
            $self->{output}->output_add(long_msg => sprintf("skipping '%s': is offline", $result->{hhmsSensorArraySwitchDescription}));
            next;
        }
        $self->{components}->{switch}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("switch '%s' status is '%s' [instance = %s]",
                                    $result->{hhmsSensorArraySwitchDescription}, $result->{hhmsSensorArraySwitchStatus}, $instance, 
                                    ));
        
        my $exit = $self->get_severity(label => 'default2', section => 'switch', value => $result->{hhmsSensorArraySwitchStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Switch '%s' status is '%s'", $result->{hhmsSensorArraySwitchDescription}, $result->{hhmsSensorArraySwitchStatus}));
        }
    }
}

1;
