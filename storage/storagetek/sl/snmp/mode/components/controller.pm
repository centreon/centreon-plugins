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

package storage::storagetek::sl::snmp::mode::components::controller;

use strict;
use warnings;
use storage::storagetek::sl::snmp::mode::components::resources qw($map_status);

my $mapping = {
    slControllerSerialNum   => { oid => '.1.3.6.1.4.1.1211.1.15.4.14.1.3' },
    slControllerStatus      => { oid => '.1.3.6.1.4.1.1211.1.15.4.14.1.4', map => $map_status },
};
my $oid_slControllerEntry = '.1.3.6.1.4.1.1211.1.15.4.14.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_slControllerEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking controllers");
    $self->{components}->{controller} = {name => 'controllers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'controller'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_slControllerEntry}})) {
        next if ($oid !~ /^$mapping->{slControllerStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_slControllerEntry}, instance => $instance);

        next if ($self->check_filter(section => 'controller', instance => $instance));
        $self->{components}->{controller}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("controller '%s' status is '%s' [instance: %s].",
                                    $result->{slControllerSerialNum}, $result->{slControllerStatus},
                                    $instance
                                    ));
        my $exit = $self->get_severity(label => 'status', section => 'controller', value => $result->{slControllerStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Controller '%s' status is '%s'",
                                                             $result->{slControllerSerialNum}, $result->{slControllerStatus}));
        }
    }
}

1;