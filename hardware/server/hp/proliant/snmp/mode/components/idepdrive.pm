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

package hardware::server::hp::proliant::snmp::mode::components::idepdrive;

use strict;
use warnings;
use centreon::plugins::misc;

# In 'CPQIDE-MIB.mib'
my %map_pdrive_status = (
    1 => 'other',
    2 => 'ok',
    3 => 'smartError',
    4 => 'failed',
);

my %map_pdrive_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

my $mapping = {
    cpqIdeAtaDiskStatus => { oid => '.1.3.6.1.4.1.232.14.2.4.1.1.6', map => \%map_pdrive_status },
    cpqIdeAtaDiskCondition => { oid => '.1.3.6.1.4.1.232.14.2.4.1.1.7', map => \%map_pdrive_condition },
};
my $oid_cpqIdeAtaDiskEntry = '.1.3.6.1.4.1.232.14.2.4.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqIdeAtaDiskEntry, start => $mapping->{cpqIdeAtaDiskStatus}->{oid}, end => $mapping->{cpqIdeAtaDiskCondition}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking ide physical drives");
    $self->{components}->{idepdrive} = {name => 'ide physical drives', total => 0, skip => 0};
    return if ($self->check_filter(section => 'idepdrive'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqIdeAtaDiskEntry}})) {
        next if ($oid !~ /^$mapping->{cpqIdeAtaDiskCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqIdeAtaDiskEntry}, instance => $instance);

        next if ($self->check_filter(section => 'idepdrive', instance => $instance));
        $self->{components}->{idepdrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("ide physical drive '%s' [status: %s] condition is %s.", 
                                    $instance,
                                    $result->{cpqIdeAtaDiskStatus},
                                    $result->{cpqIdeAtaDiskCondition}));
        my $exit = $self->get_severity(label => 'default', section => 'idepdrive', value => $result->{cpqIdeAtaDiskCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("ide physical drive '%s' is %s", 
                                                $instance, $result->{cpqIdeAtaDiskCondition}));
        }
    }
}

1;