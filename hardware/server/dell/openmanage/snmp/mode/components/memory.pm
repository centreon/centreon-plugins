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

package hardware::server::dell::openmanage::snmp::mode::components::memory;

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
my %map_failureModes = (
    0 => 'Not failure',
    1 => 'ECC single bit correction warning rate exceeded',
    2 => 'ECC single bit correction failure rate exceeded',
    4 => 'ECC multibit fault encountered',
    8 => 'ECC single bit correction logging disabled',
    16 => 'device disabled because of spare activation',
);

# In MIB '10892.mib'
my $mapping = {
    memoryDeviceStatus => { oid => '.1.3.6.1.4.1.674.10892.1.1100.50.1.5', map => \%map_status },
};
my $mapping2 = {
    memoryDeviceLocationName => { oid => '.1.3.6.1.4.1.674.10892.1.1100.50.1.8' },
};
my $mapping3 = {
    memoryDeviceSize => { oid => '.1.3.6.1.4.1.674.10892.1.1100.50.1.14' },
};
my $mapping4 = {
    memoryDeviceFailureModes => { oid => '.1.3.6.1.4.1.674.10892.1.1100.50.1.20', map => \%map_failureModes },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{memoryDeviceStatus}->{oid} }, { oid => $mapping2->{memoryDeviceLocationName}->{oid} },
        { oid => $mapping3->{memoryDeviceSize}->{oid} }, { oid => $mapping4->{memoryDeviceFailureModes}->{oid} };
}


sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking memory modules");
    $self->{components}->{memory} = {name => 'memory modules', total => 0, skip => 0};
    return if ($self->check_filter(section => 'memory'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{memoryDeviceStatus}->{oid}}})) {
        next if ($oid !~ /^$mapping->{memoryDeviceStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{memoryDeviceStatus}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{memoryDeviceLocationName}->{oid}}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$mapping3->{memoryDeviceSize}->{oid}}, instance => $instance);
        my $result4 = $self->{snmp}->map_instance(mapping => $mapping4, results => $self->{results}->{$mapping4->{memoryDeviceFailureModes}->{oid}}, instance => $instance);

        next if ($self->check_filter(section => 'memory', instance => $instance));
        
        $self->{components}->{memory}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Memory module '%s' status is '%s' [instance: %s, Location: %s, Size: %s MB, Failure mode: %s]",
                                    $instance, $result->{memoryDeviceStatus}, $instance, 
                                    $result2->{memoryDeviceLocationName}, $result3->{memoryDeviceSize}, $result4->{memoryDeviceFailureModes}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'memory', value => $result->{memoryDeviceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Memory module '%s' status is '%s'",
                                           $instance, $result->{memoryDeviceStatus}));
        }
    }
}

1;
