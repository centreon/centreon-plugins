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

package storage::dell::compellent::snmp::mode::components::ctrl;

use strict;
use warnings;
use storage::dell::compellent::snmp::mode::components::resources qw(%map_sc_status);

my $mapping = {
    scCtlrStatus    => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.13.1.3', map => \%map_sc_status },
    scCtlrName      => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.13.1.4' },
};
my $oid_scCtlrEntry = '.1.3.6.1.4.1.674.11000.2000.500.1.2.13.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_scCtlrEntry, begin => $mapping->{scCtlrStatus}->{oid}, end => $mapping->{scCtlrName}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking controllers");
    $self->{components}->{ctrl} = {name => 'controllers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'ctrl'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_scCtlrEntry}})) {
        next if ($oid !~ /^$mapping->{scCtlrStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_scCtlrEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'ctrl', instance => $instance));
        $self->{components}->{ctrl}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("controller '%s' status is '%s' [instance = %s]",
                                    $result->{scCtlrName}, $result->{scCtlrStatus}, $instance, 
                                    ));
        
        my $exit = $self->get_severity(label => 'default', section => 'ctrl', value => $result->{scCtlrStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Controller '%s' status is '%s'", $result->{scCtlrName}, $result->{scCtlrStatus}));
        }
    }
}

1;