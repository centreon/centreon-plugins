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

package network::juniper::common::screenos::snmp::mode::components::module;

use strict;
use warnings;

my %map_status = (
    1 => 'active',
    2 => 'inactive',
);

my $mapping = {
    nsSlotType => { oid => '.1.3.6.1.4.1.3224.21.5.1.2' },
    nsSlotStatus => { oid => '.1.3.6.1.4.1.3224.21.5.1.3', map => \%map_status },
};
my $oid_nsSlotEntry = '.1.3.6.1.4.1.3224.21.5.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_nsSlotEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking modules");
    $self->{components}->{module} = {name => 'module', total => 0, skip => 0};
    return if ($self->check_filter(section => 'module'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_nsSlotEntry}})) {
        next if ($oid !~ /^$mapping->{nsSlotStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_nsSlotEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'module', instance => $instance));
        $self->{components}->{module}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Module '%s' status is '%s' [instance: %s]", 
                                    $result->{nsSlotType}, $result->{nsSlotStatus}, $instance));
        my $exit = $self->get_severity(section => 'module', value => $result->{nsSlotStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Module '%s' status is '%s'", 
                                                             $result->{nsSlotType}, $result->{nsSlotStatus}));
        }
    }
}

1;
