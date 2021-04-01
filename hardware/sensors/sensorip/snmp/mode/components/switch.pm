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

package hardware::sensors::sensorip::snmp::mode::components::switch;

use strict;
use warnings;

my %map_sw_status = (
    1 => 'noStatus',
    2 => 'normal',
    4 => 'highCritical',
    6 => 'lowCritical',
    7 => 'sensorError',
    8 => 'relayOn',
    9 => 'relayOff',
);
my %map_sw_online = (
    1 => 'online',
    2 => 'offline',
);

my $mapping = {
    sensorProbeSwitchDescription => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.18.1.1' },
    sensorProbeSwitchStatus => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.18.1.3', map => \%map_sw_status },
    sensorProbeSwitchOnline => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.18.1.4', map => \%map_sw_online },
};
my $oid_sensorProbeSwitchEntry = '.1.3.6.1.4.1.3854.1.2.2.1.18.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_sensorProbeSwitchEntry, end => $mapping->{sensorProbeSwitchOnline}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking switch");
    $self->{components}->{switch} = {name => 'switch', total => 0, skip => 0};
    return if ($self->check_filter(section => 'switch'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_sensorProbeSwitchEntry}})) {
        next if ($oid !~ /^$mapping->{sensorProbeSwitchStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_sensorProbeSwitchEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'switch', instance => $instance));
        if ($result->{sensorProbeSwitchOnline} =~ /Offline/i) {  
            $self->absent_problem(section => 'switch', instance => $instance);
            next;
        }
        
        $self->{components}->{switch}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Switch sensor '%s' status is '%s' [instance : %s]", 
                                            $result->{sensorProbeSwitchDescription}, $result->{sensorProbeSwitchStatus}, $instance));
        my $exit = $self->get_severity(section => 'switch', value => $result->{sensorProbeSwitchStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Switch sensor '%s' status is '%s'", $result->{sensorProbeSwitchDescription}, $result->{sensorProbeSwitchStatus}));
        }
    }
}

1;
