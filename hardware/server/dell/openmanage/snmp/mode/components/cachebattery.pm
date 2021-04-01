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

package hardware::server::dell::openmanage::snmp::mode::components::cachebattery;

use strict;
use warnings;

my %map_state = (
    0 => 'unknown', 
    1 => 'ready', 
    2 => 'failed', 
    6 => 'degraded',
    7 => 'reconditioning',
    9 => 'high',
    10 => 'powerLow',
    12 => 'charging',
    21 => 'missing',
    36 => 'learning',
);
my %map_status = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCritical',
    5 => 'critical',
    6 => 'nonRecoverable',
);
my %map_learnState = (
    1 => 'failed',
    2 => 'active',
    4 => 'timedOut',
    8 => 'requested',
    16 => 'idle',
    32 => 'due',
);
my %map_predictedCapacity = (
    1 => 'failed',
    2 => 'ready',
    4 => 'unknown',
);

# In MIB 'dcstorag.mib'
my $mapping = {
    batteryState => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.15.1.4', map => \%map_state },
};
my $mapping2 = {
    batteryComponentStatus => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.15.1.6', map => \%map_status },
};
my $mapping3 = {
    batteryPredictedCapicity => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.15.1.10', map => \%map_predictedCapacity },
};
my $mapping4 = {
    batteryLearnState => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.15.1.12', map => \%map_learnState },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{batteryState}->{oid} }, { oid => $mapping2->{batteryComponentStatus}->{oid} },
        { oid => $mapping3->{batteryPredictedCapicity}->{oid} }, { oid => $mapping4->{batteryLearnState}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cache batteries");
    $self->{components}->{cachebattery} = {name => 'cache batteries', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cachebattery'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping2->{batteryComponentStatus}->{oid}}})) {
        next if ($oid !~ /^$mapping2->{batteryComponentStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{batteryState}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{batteryComponentStatus}->{oid}}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$mapping3->{batteryPredictedCapicity}->{oid}}, instance => $instance);
        my $result4 = $self->{snmp}->map_instance(mapping => $mapping4, results => $self->{results}->{$mapping4->{batteryLearnState}->{oid}}, instance => $instance);
        $result4->{batteryLearnState} = defined($result4->{batteryLearnState}) ? $result4->{batteryLearnState} : '-';
        $result3->{batteryPredictedCapicity} = defined($result3->{batteryPredictedCapicity}) ? $result3->{batteryPredictedCapicity} : '-';
        
        next if ($self->check_filter(section => 'cachebattery', instance => $instance));
        
        $self->{components}->{cachebattery}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Cache battery '%s' status is '%s' [instance: %s, state: %s, learn state: %s, predicted capacity: %s]",
                                    $instance, $result2->{batteryComponentStatus}, $instance, 
                                    $result->{batteryState}, $result4->{batteryLearnState}, $result3->{batteryPredictedCapicity} 
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'cachebattery', value => $result2->{batteryComponentStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Cache battery '%s' status is '%s'",
                                           $instance, $result2->{batteryComponentStatus}));
        }
    }
}

1;
