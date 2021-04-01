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

package storage::hitachi::standard::snmp::mode::components::component;

use strict;
use warnings;

my %map_status = (
    0 => 'ok',
    1 => 'abnormal',
);
my %mapping_type = (
    0 => 'drive',     
    1 => 'spare drive',
    2 => 'data drive',
    3 => 'ENC',
    5 => 'notUsed',
    6 => 'warning',
    7 => 'Other controller',
    8 => 'UPS',
    9 => 'loop',
    10 => 'path',
    11 => 'NAS Server',
    12 => 'NAS Path',
    13 => 'NAS UPS',
    14 => 'notUsed',
    15 => 'notUsed',
    16 => 'battery',
    17 => 'power supply',
    18 => 'AC',
    19 => 'BK', 
    20 => 'fan',
    21 => 'notUsed',
    22 => 'notUsed',
    23 => 'notUsed',
    24 => 'cache memory',
    25 => 'SATA spare disk',
    26 => 'SATA data drive',
    27 => 'SENC status',
    28 => 'HostConnector',
    29 => 'notUsed',
    30 => 'notUsed',
    31 => 'notUsed',
 );

my $oid_dfRegressionStatus = '.1.3.6.1.4.1.116.5.11.1.2.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_dfRegressionStatus };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking components");
    $self->{components}->{component} = {name => 'components', total => 0, skip => 0};
    return if ($self->check_filter(section => 'component'));

    return if (!defined($self->{results}->{$oid_dfRegressionStatus}->{$oid_dfRegressionStatus . '.0'}));
    
    foreach my $bit_num (sort keys %mapping_type) {
        my $bit_indicate = int($self->{results}->{$oid_dfRegressionStatus}->{$oid_dfRegressionStatus . '.0'}) & (1 << int($bit_num));
        $bit_indicate = 1 if ($bit_indicate > 0);
        my $status = $map_status{$bit_indicate};
        next if ($self->check_filter(section => 'component', instance => $mapping_type{$bit_num}));
        $self->{components}->{component}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("component '%s' status is '%s' [instance: %s].",
                                    $mapping_type{$bit_num}, $status,
                                    $mapping_type{$bit_num}
                                    ));
        my $exit = $self->get_severity(section => 'component', instance => $mapping_type{$bit_num}, value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Component '%s' status is '%s'",
                                                             $mapping_type{$bit_num}, $status));
        }
    }
}

1;