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

package hardware::server::dell::openmanage::snmp::mode::components::physicaldisk;

use strict;
use warnings;

my %map_state = (
    0 => 'unknown',
    1 => 'ready', 
    2 => 'failed', 
    3 => 'online', 
    4 => 'offline',
    6 => 'degraded',
    7 => 'recovering',
    11 => 'removed',
    15 => 'resynching',
    24 => 'rebuild',
    25 => 'noMedia',
    26 => 'formatting',
    28 => 'diagnostics',
    35 => 'initializing',
);
my %map_spareState = (
    1 => 'memberVD',
    2 => 'memberDG',
    3 => 'globalHostSpare',
    4 => 'dedicatedHostSpare',
    5 => 'notASpare',
);
my %map_status = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCritical',
    5 => 'critical',
    6 => 'nonRecoverable',
);
my %map_smartAlertIndication = (
    1 => 'no',
    2 => 'yes',
);

# In MIB 'dcstorag.mib'
my $mapping = {
    arrayDiskName => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.4.1.2' },
};
my $mapping2 = {
    arrayDiskState => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.4.1.4', map => \%map_state },
};
my $mapping3 = {
    arrayDiskSpareState => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.4.1.22', map => \%map_spareState  },
};
my $mapping4 = {
    arrayDiskComponentStatus => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.4.1.24', map => \%map_status },
};
my $mapping5 = {
    arrayDiskSmartAlertIndication => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.4.1.31', map => \%map_smartAlertIndication },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{arrayDiskName}->{oid} }, { oid => $mapping2->{arrayDiskState}->{oid} },
        { oid => $mapping3->{arrayDiskSpareState}->{oid} }, { oid => $mapping4->{arrayDiskComponentStatus}->{oid} },
        { oid => $mapping5->{arrayDiskSmartAlertIndication}->{oid} };
}


sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking physical disks");
    $self->{components}->{physicaldisk} = {name => 'physical disks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'physicaldisk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping4->{arrayDiskComponentStatus}->{oid}}})) {
        next if ($oid !~ /^$mapping4->{arrayDiskComponentStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{arrayDiskName}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{arrayDiskState}->{oid}}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$mapping3->{arrayDiskSpareState}->{oid}}, instance => $instance);
        my $result4 = $self->{snmp}->map_instance(mapping => $mapping4, results => $self->{results}->{$mapping4->{arrayDiskComponentStatus}->{oid}}, instance => $instance);
        my $result5 = $self->{snmp}->map_instance(mapping => $mapping5, results => $self->{results}->{$mapping5->{arrayDiskSmartAlertIndication}->{oid}}, instance => $instance);
        
        next if ($self->check_filter(section => 'physicaldisk', instance => $instance));
        
        $self->{components}->{physicaldisk}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Physical Disk '%s' status is '%s' [instance: %s, state: %s, spare state: %s, smart alert: %s]",
                                    $result->{arrayDiskName}, $result4->{arrayDiskComponentStatus}, $instance, 
                                    $result2->{arrayDiskState}, $result3->{arrayDiskSpareState}, 
                                    defined($result5->{arrayDiskSmartAlertIndication}) ? $result5->{arrayDiskSmartAlertIndication} : '-'
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'physicaldisk', value => $result4->{arrayDiskComponentStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Physical Disk '%s' status is '%s'",
                                           $result->{arrayDiskName}, $result4->{arrayDiskComponentStatus}));
        }
        
        if (defined($result5->{arrayDiskSmartAlertIndication})) {
            $exit = $self->get_severity(section => 'physicaldisk_smartalert', value => $result5->{arrayDiskSmartAlertIndication});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("physical disk '%s' has received a predictive failure alert",
                                                $result->{arrayDiskName}));
            }
        }
    }
}

1;
