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

package hardware::server::hp::proliant::snmp::mode::components::sasctl;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_controller_status = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
);

my %map_controller_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

# In 'CPQSCSI-MIB.mib'
my $mapping = {
    cpqSasHbaStatus => { oid => '.1.3.6.1.4.1.232.5.5.1.1.1.4', map => \%map_controller_status },
    cpqSasHbaCondition => { oid => '.1.3.6.1.4.1.232.5.5.1.1.1.5', map => \%map_controller_condition },
    cpqSasHbaSlot => { oid => '.1.3.6.1.4.1.232.5.5.1.1.1.6' },
};
my $oid_cpqSasHbaEntry = '.1.3.6.1.4.1.232.5.5.1.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqSasHbaEntry, start => $mapping->{cpqSasHbaStatus}->{oid}, end => $mapping->{cpqSasHbaSlot}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking sas controllers");
    $self->{components}->{sasctl} = {name => 'sas controllers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sasctl'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqSasHbaEntry}})) {
        next if ($oid !~ /^$mapping->{cpqSasHbaCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqSasHbaEntry}, instance => $instance);

        next if ($self->check_filter(section => 'sasctl', instance => $instance));
        $self->{components}->{sasctl}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("sas controller '%s' [slot: %s, status: %s] condition is %s.", 
                                    $instance, $result->{cpqSasHbaSlot}, $result->{cpqSasHbaStatus},
                                    $result->{cpqSasHbaCondition}));
        my $exit = $self->get_severity(label => 'default', section => 'sasctl', value => $result->{cpqSasHbaCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("sas controller '%s' is %s", 
                                            $instance, $result->{cpqSasHbaCondition}));
        }
    }
}

1;