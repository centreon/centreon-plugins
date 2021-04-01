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

package hardware::devices::video::axis::snmp::mode::components::storage;

use strict;
use warnings;

my %map_storage_status = (
    1 => 'no',
    2 => 'yes',
);

my $mapping = {
    axisStorageState => { oid => '.1.3.6.1.4.1.368.4.1.8.1.3', map => \%map_storage_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{axisStorageState}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking Storage");
    $self->{components}->{storage} = {name => 'storage', total => 0, skip => 0};
    return if ($self->check_filter(section => 'storage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{axisStorageState}->{oid}}})) {
        next if ($oid !~ /^$mapping->{axisStorageState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{axisStorageState}->{oid}}, instance => $instance);
        
        next if ($self->check_filter(section => 'storage', instance => $instance));
        $self->{components}->{storage}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("storage '%s' state is %s [instance: %s].",
                                    $instance, $result->{axisStorageState}, $instance
                                    ));
        my $exit = $self->get_severity(section => 'storage', value => $result->{axisStorageState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("storage '%s' state is %s", 
                                                             $instance, $result->{axisStorageState}));
        }
    }
}

1;
