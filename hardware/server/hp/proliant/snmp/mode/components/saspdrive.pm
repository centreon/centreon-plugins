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

package hardware::server::hp::proliant::snmp::mode::components::saspdrive;

use strict;
use warnings;

my %map_pdrive_status = (
    1 => "other",
    2 => "ok",
    3 => "predictiveFailure",
    4 => "offline",
    5 => "failed",
    6 => "missingWasOk",
    7 => "missingWasPredictiveFailure",
    8 => "missingWasOffline",
    9 => "missingWasFailed",
    10 => 'ssdWearOut',
    11 => 'missingWasSSDWearOut',
    12 => 'notAuthenticated',
    13 => 'missingWasNotAuthenticated',
);

my %map_pdrive_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

# In 'CPQSCSI-MIB.mib'
my $mapping = {
    cpqSasPhyDrvStatus => { oid => '.1.3.6.1.4.1.232.5.5.2.1.1.5', map => \%map_pdrive_status },
    cpqSasPhyDrvCondition => { oid => '.1.3.6.1.4.1.232.5.5.2.1.1.6', map => \%map_pdrive_condition },
};
my $oid_cpqSasPhyDrvEntry = '.1.3.6.1.4.1.232.5.5.2.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqSasPhyDrvEntry, start => $mapping->{cpqSasPhyDrvStatus}->{oid}, end => $mapping->{cpqSasPhyDrvCondition}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking sas physical drives");
    $self->{components}->{saspdrive} = {name => 'sas physical drives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'saspdrive'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqSasPhyDrvEntry}})) {
        next if ($oid !~ /^$mapping->{cpqSasPhyDrvCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqSasPhyDrvEntry}, instance => $instance);

        next if ($self->check_filter(section => 'saspdrive', instance => $instance));
        $self->{components}->{saspdrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("sas physical drive '%s' [status: %s] condition is %s.", 
                                    $instance,
                                    $result->{cpqSasPhyDrvStatus},
                                    $result->{cpqSasPhyDrvCondition}));
        my $exit = $self->get_severity(label => 'default', section => 'saspdrive', value => $result->{cpqSasPhyDrvCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("sas physical drive '%s' is %s", 
                                                $instance, $result->{cpqSasPhyDrvCondition}));
        }
    }
}

1;