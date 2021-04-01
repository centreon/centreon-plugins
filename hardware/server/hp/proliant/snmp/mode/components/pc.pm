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

package hardware::server::hp::proliant::snmp::mode::components::pc;

use strict;
use warnings;

my %map_pc_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

my %map_present = (
    1 => 'other',
    2 => 'absent',
    3 => 'present',
);

my %map_redundant = (
    1 => 'other',
    2 => 'not redundant',
    3 => 'redundant',
);

# In MIB 'CPQHLTH-MIB.mib'
my $mapping = {
    cpqHePwrConvPresent => { oid => '.1.3.6.1.4.1.232.6.2.13.3.1.3', map => \%map_present },
    cpqHePwrConvRedundant => { oid => '.1.3.6.1.4.1.232.6.2.13.3.1.6', map => \%map_redundant },
    cpqHePwrConvRedundantGroupId => { oid => '.1.3.6.1.4.1.232.6.2.13.3.1.7' },
    cpqHePwrConvCondition => { oid => '.1.3.6.1.4.1.232.6.2.13.3.1.8', map => \%map_pc_condition },
};
my $oid_cpqHePowerConverterEntry = '.1.3.6.1.4.1.232.6.2.13.3.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_cpqHePowerConverterEntry, start => $mapping->{cpqHePwrConvPresent}->{oid}, end => $mapping->{cpqHePwrConvCondition}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power converters");
    $self->{components}->{pc} = {name => 'power converters', total => 0, skip => 0};
    return if ($self->check_filter(section => 'pc'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqHePowerConverterEntry}})) {
        next if ($oid !~ /^$mapping->{cpqHePwrConvPresent}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqHePowerConverterEntry}, instance => $instance);

        next if ($self->check_filter(section => 'pc', instance => $instance));
        next if ($result->{cpqHePwrConvPresent} !~ /present/i && 
                 $self->absent_problem(section => 'pc', instance => $instance));
        
        $self->{components}->{pc}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("powerconverter '%s' status is %s [redundance: %s, redundant group: %s].",
                                    $instance, $result->{cpqHePwrConvCondition},
                                    $result->{cpqHePwrConvRedundant}, $result->{cpqHePwrConvRedundantGroupId}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'pc', value => $result->{cpqHePwrConvCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("powerconverter '%s' status is %s",
                                           $instance, $result->{cpqHePwrConvCondition}));
        }
    }
}

1;