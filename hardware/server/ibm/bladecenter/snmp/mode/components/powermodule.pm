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

package hardware::server::ibm::bladecenter::snmp::mode::components::powermodule;

use strict;
use warnings;

my %map_pw_state = (
    0 => 'unknown',
    1 => 'good',
    2 => 'warning',
    3 => 'notAvailable',
    4 => 'critical',
);
my %map_pw_exists = (
    0 => 'false',
    1 => 'true',
);

# In MIB 'mmblade.mib' and 'cme.mib'
my $mapping = {
    powerModuleExists => { oid => '.1.3.6.1.4.1.2.3.51.2.2.4.1.1.2', map => \%map_pw_exists },
    powerModuleState => { oid => '.1.3.6.1.4.1.2.3.51.2.2.4.1.1.3', map => \%map_pw_state  },
    powerModuleDetails => { oid => '.1.3.6.1.4.1.2.3.51.2.2.4.1.1.4' },
};
my $oid_powerModuleHealthEntry = '.1.3.6.1.4.1.2.3.51.2.2.4.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_powerModuleHealthEntry, start => $mapping->{powerModuleExists}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power modules");
    $self->{components}->{powermodule} = {name => 'power modules', total => 0, skip => 0};
    return if ($self->check_filter(section => 'powermodule'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_powerModuleHealthEntry}})) {
        next if ($oid !~ /^$mapping->{powerModuleState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_powerModuleHealthEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'powermodule', instance => $instance));
        next if ($result->{powerModuleExists} =~ /No/i && 
                 $self->absent_problem(section => 'powermodule', instance => $instance));
        $self->{components}->{powermodule}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power module '%s' state is %s [details: %s]", 
                                    $instance, $result->{powerModuleState}, $result->{powerModuleDetails}));
        my $exit = $self->get_severity(section => 'powermodule', value => $result->{powerModuleState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power module '%s' state is %s", 
                                            $instance, $result->{powerModuleState}));
        }
    }
}

1;