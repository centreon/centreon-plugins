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

package hardware::server::hp::proliant::snmp::mode::components::dapdrive;

use strict;
use warnings;

my %map_dapdrive_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);
my %map_dapdrive_status = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'predictiveFailure',
    5 => 'erasing',
    6 => 'eraseDone',
    7 => 'eraseQueued',
);
# In 'CPQIDA-MIB.mib'
my $mapping = {
    cpqDaPhyDrvStatus => { oid => '.1.3.6.1.4.1.232.3.2.5.1.1.6', map => \%map_dapdrive_status },
};
my $mapping2 = {
    cpqDaPhyDrvCondition => { oid => '.1.3.6.1.4.1.232.3.2.5.1.1.37', map => \%map_dapdrive_condition },
};
my $oid_cpqDaPhyDrvCondition = '.1.3.6.1.4.1.232.3.2.5.1.1.37';
my $oid_cpqDaPhyDrvStatus = '.1.3.6.1.4.1.232.3.2.5.1.1.6';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqDaPhyDrvStatus }, { oid => $oid_cpqDaPhyDrvCondition };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking da physical drives");
    $self->{components}->{dapdrive} = {name => 'da physical drives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'dapdrive'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqDaPhyDrvCondition}})) {
        next if ($oid !~ /^$mapping2->{cpqDaPhyDrvCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqDaPhyDrvStatus}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqDaPhyDrvCondition}, instance => $instance);

        next if ($self->check_filter(section => 'dapdrive', instance => $instance));
        $self->{components}->{dapdrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("da physical drive '%s' [status: %s] condition is %s.", 
                                    $instance,
                                    $result->{cpqDaPhyDrvStatus},
                                    $result2->{cpqDaPhyDrvCondition}));
        my $exit = $self->get_severity(label => 'default', section => 'dapdrive', value => $result2->{cpqDaPhyDrvCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("da physical drive '%s' is %s", 
                                                $instance, $result2->{cpqDaPhyDrvCondition}));
        }
    }
}

1;