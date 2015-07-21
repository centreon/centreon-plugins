#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package hardware::server::dell::openmanage::mode::components::connector;

use strict;
use warnings;

my %state = (
    0 => 'unknown',
    1 => 'ready', 
    2 => 'failed', 
    3 => 'online', 
    4 => 'offline',
    6 => 'degraded',
);

my %status = (
    1 => ['other', 'UNKNOWN'],
    2 => ['unknown', 'UNKNOWN'],
    3 => ['ok', 'OK'],
    4 => ['nonCritical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'CRITICAL'],
);

my %busType = (
    1 => 'SCSI',
    2 => 'IDE',
    3 => 'Fibre Channel',
    4 => 'SSA',
    6 => 'USB',
    7 => 'SATA',
    8 => 'SAS',
);

sub check {
    my ($self) = @_;

    # In MIB '10893.mib'
    $self->{output}->output_add(long_msg => "Checking Connectors (Channels)");
    $self->{components}->{connector} = {name => 'connectors', total => 0};
    return if ($self->check_exclude('connector'));
   
    my $oid_channelName = '.1.3.6.1.4.1.674.10893.1.20.130.2.1.2';
    my $oid_channelState = '.1.3.6.1.4.1.674.10893.1.20.130.2.1.3';
    my $oid_channelComponentStatus = '.1.3.6.1.4.1.674.10893.1.20.130.2.1.8';
    my $oid_channelBusType = '.1.3.6.1.4.1.674.10893.1.20.130.2.1.11';

    my $result = $self->{snmp}->get_table(oid => $oid_channelName);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_channelState, $oid_channelComponentStatus, $oid_channelBusType],
                        instances => [keys %$result],
                        instance_regexp => '(\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $channel_Index = $1;
        
        my $channel_name = $result->{$key};
        my $channel_state = $result2->{$oid_channelState . '.' . $channel_Index};
        my $channel_componentStatus = $result2->{$oid_channelComponentStatus . '.' . $channel_Index};
        my $channel_busType = $result2->{$oid_channelBusType . '.' . $channel_Index};
        
        $self->{components}->{connector}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("connector '%s' status is '%s', state is '%s' [index: %d, bus: %s].",
                                    $channel_name, ${$status{$channel_componentStatus}}[0], $state{$channel_state},
                                    $channel_Index, $busType{$channel_busType}
                                    ));

        if ($channel_componentStatus != 3) {
            $self->{output}->output_add(severity =>  ${$status{$channel_componentStatus}}[1],
                                        short_msg => sprintf("connector '%s' status is '%s' [index: %d, bus: %s]",
                                           $channel_name, ${$status{$channel_componentStatus}}[0], $channel_Index, $busType{$channel_busType}));
        }

    }
}

1;
