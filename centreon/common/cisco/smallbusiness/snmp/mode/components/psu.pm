#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package centreon::common::cisco::smallbusiness::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (
    1 => 'normal',
    2 => 'warning',
    3 => 'critical',
    4 => 'shutdown',
    5 => 'notPresent',
    6 => 'notFunctioning'
);

my $mapping = {
    rlEnvMonSupplyStatusDescr => { oid => '.1.3.6.1.4.1.9.6.1.101.83.1.2.1.2' },
    rlEnvMonSupplyState => { oid => '.1.3.6.1.4.1.9.6.1.101.83.1.2.1.3', map => \%map_psu_status },
};
my $oid_rlEnvMonSupplyStatusEntry = '.1.3.6.1.4.1.9.6.1.101.83.1.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_rlEnvMonSupplyStatusEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rlEnvMonSupplyStatusEntry}})) {
        next if ($oid !~ /^$mapping->{rlEnvMonSupplyState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_rlEnvMonSupplyStatusEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'psu', instance => $instance));
        if ($result->{rlEnvMonSupplyState} =~ /notPresent/i) {  
            $self->absent_problem(section => 'psu', instance => $instance);
            next;
        }
        
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is '%s' [instance = %s]",
                                                        $result->{rlEnvMonSupplyStatusDescr}, $result->{rlEnvMonSupplyState}, $instance));
        my $exit = $self->get_severity(section => 'psu', value => $result->{rlEnvMonSupplyState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Power supply '%s' status is '%s'", $result->{rlEnvMonSupplyStatusDescr}, $result->{rlEnvMonSupplyState}));
        }
    }
}

1;