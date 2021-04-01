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

package hardware::server::hp::proliant::snmp::mode::components::scsildrive;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_ldrive_status = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'unconfigured',
    5 => 'recovering',
    6 => 'readyForRebuild',
    7 => 'rebuilding',
    8 => 'wrongDrive',
    9 => 'badConnect',
    10 => 'degraded',
    11 => 'disabled',
);

my %map_ldrive_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

# In 'CPQSCSI-MIB.mib'

my $mapping = {
    cpqScsiLogDrvStatus => { oid => '.1.3.6.1.4.1.232.5.2.3.1.1.5', map => \%map_ldrive_status },
};
my $mapping2 = {
    cpqScsiLogDrvCondition => { oid => '.1.3.6.1.4.1.232.5.2.3.1.1.8', map => \%map_ldrive_condition },    
};
my $oid_cpqScsiLogDrvCondition = '.1.3.6.1.4.1.232.5.2.3.1.1.8';
my $oid_cpqScsiLogDrvStatus = '.1.3.6.1.4.1.232.5.2.3.1.1.5';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqScsiLogDrvStatus }, { oid => $oid_cpqScsiLogDrvCondition };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking scsi logical drives");
    $self->{components}->{scsildrive} = {name => 'scsi logical drives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'scsildrive'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqScsiLogDrvCondition}})) {
        next if ($oid !~ /^$mapping2->{cpqScsiLogDrvCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqScsiLogDrvStatus}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqScsiLogDrvCondition}, instance => $instance);
        
        next if ($self->check_filter(section => 'scsildrive', instance => $instance));
        $self->{components}->{scsildrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("scsi logical drive '%s' status is %s [condition: %s].", 
                                    $instance,
                                    $result2->{oid_cpqScsiLogDrvStatus},
                                    $result->{oid_cpqScsiLogDrvCondition}));
        my $exit = $self->get_severity(section => 'scsildrive', value => $result2->{oid_cpqScsiLogDrvStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("scsi logical drive '%s' is %s", 
                                                $instance, $result2->{oid_cpqScsiLogDrvStatus}));
        }
    }
}

1;