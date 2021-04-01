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

package hardware::server::dell::openmanage::snmp::mode::components::logicaldrive;

use strict;
use warnings;

my %map_state = (
    0 => 'unknown',
    1 => 'ready', 
    2 => 'failed', 
    3 => 'online', 
    4 => 'offline',
    6 => 'degraded',
    15 => 'resynching',
    24 => 'rebuild',
    26 => 'formatting',
    35 => 'initializing',
);
my %map_layout = (
    1 => 'Concatened',
    2 => 'RAID-0',
    3 => 'RAID-1',
    4 => 'RAID-2',
    5 => 'RAID-3',
    6 => 'RAID-4',
    7 => 'RAID-5',
    8 => 'RAID-6',
    9 => 'RAID-7',
    10 => 'RAID-10',
    11 => 'RAID-30',
    12 => 'RAID-50',
    13 => 'Add spares', 
    14 => 'Delete logical',
    15 => 'Transform logical',
    18 => 'RAID-0-plus-1 - Mylex only',
    19 => 'Concatened RAID 1',
    20 => 'Concatened RAID 5',
    21 => 'no RAID',
    22 => 'RAID Morph - Adapted only',
);
my %map_status = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCritical',
    5 => 'critical',
    6 => 'nonRecoverable',
);

# In MIB 'dcstorag.mib'
my $mapping = {
    virtualDiskName => { oid => '.1.3.6.1.4.1.674.10893.1.20.140.1.1.2' },
    virtualDiskDeviceName => { oid => '.1.3.6.1.4.1.674.10893.1.20.140.1.1.3' },
    virtualDiskState => { oid => '.1.3.6.1.4.1.674.10893.1.20.140.1.1.4', map => \%map_state },
};
my $mapping2 = {
    virtualDiskLengthInMB => { oid => '.1.3.6.1.4.1.674.10893.1.20.140.1.1.6' },
};
my $mapping3 = {
    virtualDiskLayout => { oid => '.1.3.6.1.4.1.674.10893.1.20.140.1.1.13', map => \%map_layout },
};
my $mapping4 = {
    virtualDiskComponentStatus => { oid => '.1.3.6.1.4.1.674.10893.1.20.140.1.1.20', map => \%map_status },
};
my $oid_virtualDiskEntry = '.1.3.6.1.4.1.674.10893.1.20.140.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_virtualDiskEntry, start => $mapping->{virtualDiskName}->{oid}, end => $mapping->{virtualDiskState}->{oid} },
        { oid => $mapping2->{virtualDiskLengthInMB}->{oid} }, { oid => $mapping3->{virtualDiskLayout}->{oid} }, { oid => $mapping4->{virtualDiskComponentStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking logical drives");
    $self->{components}->{logicaldrive} = {name => 'logical drives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'logicaldrive'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping4->{virtualDiskComponentStatus}->{oid}}})) {
        next if ($oid !~ /^$mapping4->{virtualDiskComponentStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_virtualDiskEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{virtualDiskLengthInMB}->{oid}}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$mapping3->{virtualDiskLayout}->{oid}}, instance => $instance);
        my $result4 = $self->{snmp}->map_instance(mapping => $mapping4, results => $self->{results}->{$mapping4->{virtualDiskComponentStatus}->{oid}}, instance => $instance);

        next if ($self->check_filter(section => 'logicaldrive', instance => $instance));
        
        $self->{components}->{logicaldrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Logical drive '%s' status is '%s' [instance: %s, size: %s MB, layout: %s, state: %s, device name: %s]",
                                    $result->{virtualDiskName}, $result4->{virtualDiskComponentStatus}, $instance, 
                                    $result2->{virtualDiskLengthInMB}, $result3->{virtualDiskLayout}, 
                                    $result->{virtualDiskState}, $result->{virtualDiskDeviceName}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'logicaldrive', value => $result4->{virtualDiskComponentStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Logical drive '%s' status is '%s'",
                                           $result->{virtualDiskName}, $result4->{virtualDiskComponentStatus}));
        }
    }
}

1;
