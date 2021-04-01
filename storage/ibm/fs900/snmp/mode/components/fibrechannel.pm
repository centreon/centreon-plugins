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

package storage::ibm::fs900::snmp::mode::components::fibrechannel;

use strict;
use warnings;

# In MIB 'IBM-FLASHSYSTEM.MIB'
my $mapping = {
    fcObject => { oid => '.1.3.6.1.4.1.2.6.255.1.1.2.1.1.2' },
    fcState => { oid => '.1.3.6.1.4.1.2.6.255.1.1.2.1.1.5' },
};
my $oid_fcTableIndex = '.1.3.6.1.4.1.2.6.255.1.1.2.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_fcTableIndex };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fibre channels");
    $self->{components}->{fibrechannel} = {name => 'fibrechannels', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fibrechannel'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fcTableIndex}})) {
        next if ($oid !~ /^$mapping->{fcObject}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fcTableIndex}, instance => $instance);
        
        next if ($self->check_filter(section => 'fibrechannel', instance => $instance));
        
        $self->{components}->{fibrechannel}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fibre channel '%s' [instance = %s, state = %s]",
                                    $result->{fcObject}, $instance, $result->{fcState}));

        my $exit = $self->get_severity(section => 'fibrechannel', value => $result->{fcState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fibre channel '%s' state is %s", 
                                            $instance, $result->{fcState}));
        }
    }
}

1;