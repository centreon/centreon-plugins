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

package hardware::server::dell::openmanage::snmp::mode::components::battery;

use strict;
use warnings;

my %map_status = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCritical',
    5 => 'critical',
    6 => 'nonRecoverable',
);

my %map_reading = (
    1 => 'Predictive Failure',
    2 => 'Failed',
    4 => 'Presence Detected',
);

# In MIB '10892.mib'
my $mapping = {
    batteryStatus => { oid => '.1.3.6.1.4.1.674.10892.1.600.50.1.5', map => \%map_status },
    batteryReading => { oid => '.1.3.6.1.4.1.674.10892.1.600.50.1.6', map => \%map_reading },
    batteryLocationName => { oid => '.1.3.6.1.4.1.674.10892.1.600.50.1.7' },
};
my $oid_batteryTableEntry = '.1.3.6.1.4.1.674.10892.1.600.50.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_batteryTableEntry, start => $mapping->{batteryStatus}->{oid}, end => $mapping->{batteryLocationName}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking batteries");
    $self->{components}->{battery} = {name => 'batteries', total => 0, skip => 0};
    return if ($self->check_filter(section => 'battery'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_batteryTableEntry}})) {
        next if ($oid !~ /^$mapping->{batteryStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_batteryTableEntry}, instance => $instance);

        next if ($self->check_filter(section => 'battery', instance => $instance));
        
        $self->{components}->{battery}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Battery '%s' status is '%s' [instance: %s, reading: %s, location: %s]",
                                    $instance, $result->{batteryStatus}, $instance, $result->{batteryReading}, $result->{batteryLocationName}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'battery', value => $result->{batteryStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Battery '%s' status is '%s'",
                                           $instance, $result->{batteryStatus}));
        }
    }
}

1;
