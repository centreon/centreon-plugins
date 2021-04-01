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

package storage::dell::fluidfs::snmp::mode::components::substorage;

use strict;
use warnings;

my $mapping = {
    fluidFSStorageSubsystemType                 => { oid => '.1.3.6.1.4.1.674.11000.2000.200.1.32.1.2' },
    fluidFSStorageSubsystemLunsAccessibility    => { oid => '.1.3.6.1.4.1.674.11000.2000.200.1.32.1.3' },
};
my $oid_fluidFSStorageSubsystemEntry = '.1.3.6.1.4.1.674.11000.2000.200.1.32.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_fluidFSStorageSubsystemEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking storage subsystem");
    $self->{components}->{substorage} = {name => 'substorage', total => 0, skip => 0};
    return if ($self->check_filter(section => 'substorage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fluidFSStorageSubsystemEntry}})) {
        next if ($oid !~ /^$mapping->{fluidFSStorageSubsystemLunsAccessibility}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fluidFSStorageSubsystemEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'substorage', instance => $instance));
        $self->{components}->{substorage}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("storage subsystem '%s' status is '%s' [instance = %s]",
                                    $result->{fluidFSStorageSubsystemType},
                                    $result->{fluidFSStorageSubsystemLunsAccessibility}, $instance
                                    ));
        
        my $exit = $self->get_severity(label => 'default', section => 'substorage', value => $result->{fluidFSStorageSubsystemLunsAccessibility});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Storage subsystem '%s' status is '%s'",
                                            $result->{fluidFSStorageSubsystemType},
                                            $result->{fluidFSStorageSubsystemLunsAccessibility}
                                       ));
        }
    }
}

1;