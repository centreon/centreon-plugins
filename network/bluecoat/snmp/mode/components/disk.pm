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

package network::bluecoat::snmp::mode::components::disk;

use strict;
use warnings;

my %map_status = (
    1 => 'present',
    2 => 'initializing',
    3 => 'inserted',
    4 => 'offline',
    5 => 'removed',
    6 => 'notpresent',
    7 => 'empty',
    8 => 'ioerror',
    9 => 'unusable',
    10 => 'unknown',
);

# In MIB 'BLUECOAT-SG-DISK-MIB'
my $mapping = {
    deviceDiskStatus => { oid => '.1.3.6.1.4.1.3417.2.2.1.1.1.1.3', map => \%map_status },
    deviceDiskSerialN => { oid => '.1.3.6.1.4.1.3417.2.2.1.1.1.1.8' },
};
my $oid_deviceDiskValueEntry = '.1.3.6.1.4.1.3417.2.2.1.1.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_deviceDiskValueEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'disk'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_deviceDiskValueEntry}})) {
        next if ($oid !~ /^$mapping->{deviceDiskStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_deviceDiskValueEntry}, instance => $instance);
        
        next if ($result->{deviceDiskStatus} =~ /notpresent/i && 
                 $self->absent_problem(section => 'disk', instance => $instance));
        next if ($self->check_filter(section => 'disk', instance => $instance));
        $self->{components}->{disk}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Disk '%s' status is '%s' [instance: %s]", 
                                    $result->{deviceDiskSerialN}, $result->{deviceDiskStatus}, 
                                    $instance));
        my $exit = $self->get_severity(section => 'disk', value => $result->{deviceDiskStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' status is %s", 
                                                            $result->{deviceDiskSerialN}, $result->{deviceDiskStatus}));
        }
    }
}

1;