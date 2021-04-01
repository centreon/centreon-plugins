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

package centreon::common::adic::tape::snmp::mode::components::component;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_status = (
    1 => 'unknown',
    2 => 'unused', 
    3 => 'ok', 
    4 => 'warning', 
    5 => 'failed',
);

# In MIB 'ADIC-INTELLIGENT-STORAGE-MIB'
my $mapping = {
    componentDisplayName => { oid => '.1.3.6.1.4.1.3764.1.1.30.10.1.3' },
    componentStatus => { oid => '.1.3.6.1.4.1.3764.1.1.30.10.1.8', map => \%map_status },
};
my $oid_componentEntry = '.1.3.6.1.4.1.3764.1.1.30.10.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_componentEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking components");
    $self->{components}->{component} = {name => 'components', total => 0, skip => 0};
    return if ($self->check_filter(section => 'component'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_componentEntry}})) {
        next if ($oid !~ /^$mapping->{componentStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_componentEntry}, instance => $instance);

        next if ($self->check_filter(section => 'component', instance => $result->{componentDisplayName}));
        $self->{components}->{component}->{total}++;

        $result->{componentDisplayName} =~ s/\s+/ /g;
        $result->{componentDisplayName} = centreon::plugins::misc::trim($result->{componentDisplayName});
        $self->{output}->output_add(long_msg => sprintf("component '%s' status is %s [instance: %s].",
                                    $result->{componentDisplayName}, $result->{componentStatus},
                                    $result->{componentDisplayName}
                                    ));
        my $exit = $self->get_severity(section => 'component', value => $result->{componentStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Component '%s' status is %s",
                                                             $result->{componentDisplayName}, $result->{componentStatus}));
        }
    }
}

1;