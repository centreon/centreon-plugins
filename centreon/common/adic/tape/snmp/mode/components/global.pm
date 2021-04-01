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

package centreon::common::adic::tape::snmp::mode::components::global;

use strict;
use warnings;

my %map_status = (
    1 => 'good',
    2 => 'failed',
    3 => 'degraded',
    4 => 'warning',
    5 => 'informational',
    6 => 'unknown',
    7 => 'invalid',
);
my %map_agent_status = (
    1 => 'other', 
    2 => 'unknown', 
    3 => 'ok',
    4 => 'non-critical',
    5 => 'critical', 
    6 => 'non-recoverable',
);

# In MIB 'ADIC-TAPE-LIBRARY-MIB'
my $mapping = {
    GlobalStatus => { oid => '.1.3.6.1.4.1.3764.1.10.10.1.8', map => \%map_status }, # libraryGlobalStatus
};
# In MIB 'ADIC-INTELLIGENT-STORAGE-MIB'
my $mapping2 = {
    GlobalStatus => { oid => '.1.3.6.1.4.1.3764.1.1.20.1', map => \%map_agent_status }, # agentGlobalStatus
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{GlobalStatus}->{oid} }, 
        { oid => $mapping2->{GlobalStatus}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking global");
    $self->{components}->{global} = {name => 'global', total => 0, skip => 0};
    return if ($self->check_filter(section => 'global'));

    my $instance = '0';
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{GlobalStatus}->{oid}}, instance => $instance);
    if (!defined($result->{GlobalStatus})) {
        $result = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{GlobalStatus}->{oid}}, instance => $instance);
    }
    if (!defined($result->{GlobalStatus})) {
        $self->{output}->output_add(long_msg => "skipping global status: no value."); 
        return ;
    }

    return if ($self->check_filter(section => 'global', instance => $instance));
    $self->{components}->{global}->{total}++;

    $self->{output}->output_add(long_msg => sprintf("library global status is %s [instance: %s].",
                                                    $result->{GlobalStatus}, $instance
                                ));
    my $exit = $self->get_severity(section => 'global', label => 'default', value => $result->{GlobalStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity =>  $exit,
                                    short_msg => sprintf("Library global status is %s",
                                                         $result->{GlobalStatus}));
    }
}

1;