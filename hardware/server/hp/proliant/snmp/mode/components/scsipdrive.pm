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

package hardware::server::hp::proliant::snmp::mode::components::scsipdrive;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_pdrive_status = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'notConfigured',
    5 => 'badCable',
    6 => 'missingWasOk',
    7 => 'missingWasFailed',
    8 => 'predictiveFailure',
    9 => 'missingWasPredictiveFailure',
    10 => 'offline',
    11 => 'missingWasOffline',
    12 => 'hardError',
);

my %map_pdrive_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

# In 'CPQSCSI-MIB.mib'

my $mapping = {
    cpqScsiPhyDrvStatus => { oid => '.1.3.6.1.4.1.232.5.2.4.1.1.9', map => \%map_pdrive_status },
};
my $mapping2 = {
    cpqScsiPhyDrvCondition => { oid => '.1.3.6.1.4.1.232.5.2.4.1.1.26', map => \%map_pdrive_condition },    
};
my $oid_cpqScsiPhyDrvCondition = '.1.3.6.1.4.1.232.5.2.4.1.1.26';
my $oid_cpqScsiPhyDrvStatus = '.1.3.6.1.4.1.232.5.2.4.1.1.9';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqScsiPhyDrvStatus }, { oid => $oid_cpqScsiPhyDrvCondition };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking scsi physical drives");
    $self->{components}->{scsipdrive} = {name => 'scsi physical drives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'scsipdrive'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqScsiPhyDrvCondition}})) {
        next if ($oid !~ /^$mapping->{cpqScsiPhyDrvCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqScsiPhyDrvStatus}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqScsiPhyDrvCondition}, instance => $instance);
        
        next if ($self->check_filter(section => 'scsipdrive', instance => $instance));
        $self->{components}->{scsipdrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("scsi physical drive '%s' [status: %s] condition is %s.", 
                                    $instance,
                                    $result->{cpqScsiPhyDrvStatus},
                                    $result2->{cpqScsiPhyDrvCondition}));
        my $exit = $self->get_severity(label => 'default', section => 'scsipdrive', value => $result2->{cpqScsiPhyDrvCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("scsi physical drive '%s' is %s", 
                                                $instance, $result2->{cpqScsiPhyDrvCondition}));
        }
    }
}

1;