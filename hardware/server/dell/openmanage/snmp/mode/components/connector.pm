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

package hardware::server::dell::openmanage::snmp::mode::components::connector;

use strict;
use warnings;

my %map_state = (
    0 => 'unknown',
    1 => 'ready', 
    2 => 'failed', 
    3 => 'online', 
    4 => 'offline',
    6 => 'degraded',
);
my %map_status = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCritical',
    5 => 'critical',
    6 => 'nonRecoverable',
);
my %map_busType = (
    1 => 'SCSI',
    2 => 'IDE',
    3 => 'Fibre Channel',
    4 => 'SSA',
    6 => 'USB',
    7 => 'SATA',
    8 => 'SAS',
);

# In MIB 'dcstorag.mib'
my $mapping = {
    channelName => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.2.1.2' },
    channelState => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.2.1.3', map => \%map_state },
};
my $mapping2 = {
    channelComponentStatus => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.2.1.8', map => \%map_status },
};
my $mapping3 = {
    channelBusType => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.2.1.11', map => \%map_busType },
};
my $oid_channelEntry = '.1.3.6.1.4.1.674.10893.1.20.130.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_channelEntry, start => $mapping->{channelName}->{oid}, end => $mapping->{channelState}->{oid} }, 
        { oid => $mapping2->{channelComponentStatus}->{oid} },
        { oid => $mapping3->{channelBusType}->{oid} } ;
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking connectors (channels)");
    $self->{components}->{connector} = {name => 'connectors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'connector'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping2->{channelComponentStatus}->{oid}}})) {
        next if ($oid !~ /^$mapping2->{channelComponentStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_channelEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{channelComponentStatus}->{oid}}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$mapping3->{channelBusType}->{oid}}, instance => $instance);
        $result3->{channelBusType} = defined($result3->{channelBusType}) ? $result3->{channelBusType} : '-';
        
        next if ($self->check_filter(section => 'connector', instance => $instance));
        
        $self->{components}->{connector}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Connector '%s' status is '%s' [instance: %s, state: %s, bus type: %s]",
                                    $result->{channelName}, $result2->{channelComponentStatus}, $instance, 
                                    $result->{channelState}, $result3->{channelBusType} 
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'connector', value => $result2->{channelComponentStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Connector '%s' status is '%s'",
                                           $result->{channelName}, $result2->{channelComponentStatus}));
        }
    }
}

1;
