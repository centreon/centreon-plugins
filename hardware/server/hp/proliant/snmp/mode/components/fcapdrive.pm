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

package hardware::server::hp::proliant::snmp::mode::components::fcapdrive;

use strict;
use warnings;

my %map_fcapdrive_status = (
    1 => 'other',
    2 => 'unconfigured',
    3 => 'ok',
    4 => 'threshExceeded',
    5 => 'predictiveFailure',
    6 => 'failed',
    7 => 'unsupportedDrive',
);

my %map_fcapdrive_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

# In 'CPQFCA-MIB.mib'

my $mapping = {
    cpqFcaPhyDrvStatus => { oid => '.1.3.6.1.4.1.232.16.2.5.1.1.6', map => \%map_fcapdrive_status },
};
my $mapping2 = {
    cpqFcaPhyDrvCondition => { oid => '.1.3.6.1.4.1.232.16.2.5.1.1.31', map => \%map_fcapdrive_condition },
};
my $oid_cpqFcaPhyDrvCondition = '.1.3.6.1.4.1.232.16.2.5.1.1.31';
my $oid_cpqFcaPhyDrvStatus = '.1.3.6.1.4.1.232.16.2.5.1.1.6';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqFcaPhyDrvCondition }, { oid => $oid_cpqFcaPhyDrvStatus };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fca physical drives");
    $self->{components}->{fcapdrive} = {name => 'fca physical drives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fcapdrive'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqFcaPhyDrvCondition}})) {
        next if ($oid !~ /^$mapping2->{cpqFcaPhyDrvCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqFcaPhyDrvStatus}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqFcaPhyDrvCondition}, instance => $instance);

        next if ($self->check_filter(section => 'fcapdrive', instance => $instance));
        $self->{components}->{fcapdrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fca physical drive '%s' [status: %s] condition is %s.", 
                                    $instance,
                                    $result->{cpqFcaPhyDrvStatus},
                                    $result2->{cpqFcaPhyDrvCondition}));
        my $exit = $self->get_severity(label => 'default', section => 'fcapdrive', value => $result2->{cpqFcaPhyDrvCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => short_msg => sprintf("fca physical drive '%s' is %s", 
                                                $instance, $result2->{cpqFcaPhyDrvCondition}));
        }
    }
}

1;