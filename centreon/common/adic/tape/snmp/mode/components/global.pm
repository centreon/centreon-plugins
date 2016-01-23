#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

# In MIB 'ADIC-TAPE-LIBRARY-MIB'
my $mapping = {
    libraryGlobalStatus => { oid => '.1.3.6.1.4.1.3764.1.10.10.1.8', map => \%map_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{libraryGlobalStatus}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking global");
    $self->{components}->{global} = {name => 'global', total => 0, skip => 0};
    return if ($self->check_filter(section => 'global'));

    my $instance = '0';
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{libraryGlobalStatus}->{oid}}, instance => $instance);
    if (!defined($result->{libraryGlobalStatus})) {
        $self->{output}->output_add(long_msg => "skipping global status: no value."); 
        return ;
    }

    return if ($self->check_filter(section => 'global', instance => $instance));
    $self->{components}->{global}->{total}++;

    $self->{output}->output_add(long_msg => sprintf("library global status is %s [instance: %s].",
                                                    $result->{libraryGlobalStatus}, $instance
                                ));
    my $exit = $self->get_severity(section => 'global', label => 'default', value => $result->{libraryGlobalStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity =>  $exit,
                                    short_msg => sprintf("Library global status is %s",
                                                         $result->{libraryGlobalStatus}));
    }
}

1;