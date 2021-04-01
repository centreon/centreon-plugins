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

package hardware::server::hp::proliant::snmp::mode::components::sasldrive;

use strict;
use warnings;

my %map_ldrive_status = (
    1 => "other",
    2 => "ok",
    3 => "degraded",
    4 => "rebuilding",
    5 => "failed",
    6 => "offline",
);

my %map_ldrive_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

# In 'CPQSCSI-MIB.mib'
my $mapping = {
    cpqSasLogDrvStatus => { oid => '.1.3.6.1.4.1.232.5.5.3.1.1.4', map => \%map_ldrive_status },
    cpqSasLogDrvCondition => { oid => '.1.3.6.1.4.1.232.5.5.3.1.1.5', map => \%map_ldrive_condition },,
};
my $oid_cpqSasLogDrvEntry = '.1.3.6.1.4.1.232.5.5.3.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqSasLogDrvEntry, start => $mapping->{cpqSasLogDrvStatus}->{oid}, end => $mapping->{cpqSasLogDrvCondition}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking sas logical drives");
    $self->{components}->{sasldrive} = {name => 'sas logical drives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sasldrive'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqSasLogDrvEntry}})) {
        next if ($oid !~ /^$mapping->{cpqSasLogDrvStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqSasLogDrvEntry}, instance => $instance);

        next if ($self->check_filter(section => 'sasldrive', instance => $instance));
        $self->{components}->{sasldrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("sas logical drive '%s' status is %s [condition: %s].", 
                                    $instance,
                                    $result->{cpqSasLogDrvStatus},
                                    $result->{cpqSasLogDrvCondition}));
        my $exit = $self->get_severity(section => 'sasldrive', value => $result->{cpqSasLogDrvStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("sas logical drive '%s' is %s", 
                                                $instance, $result->{cpqSasLogDrvStatus}));
        }
    }
}

1;