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

package network::ruggedcom::mode::components::psu;

use strict;
use warnings;

my %map_states_psu = (
    1 => 'notPresent',
    2 => 'functional',
    3 => 'notFunctional',
    4 => 'notConnected',
);

my $oid_rcDeviceStsPowerSupply1_entry = '.1.3.6.1.4.1.15004.4.2.2.4';
my $oid_rcDeviceStsPowerSupply1 = '.1.3.6.1.4.1.15004.4.2.2.4.0';
my $oid_rcDeviceStsPowerSupply2_entry = '.1.3.6.1.4.1.15004.4.2.2.5';
my $oid_rcDeviceStsPowerSupply2 = '.1.3.6.1.4.1.15004.4.2.2.5.0';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_rcDeviceStsPowerSupply1_entry }, { oid => $oid_rcDeviceStsPowerSupply2_entry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    my $instance = 0;
    foreach my $value (($self->{results}->{$oid_rcDeviceStsPowerSupply1}, $self->{results}->{$oid_rcDeviceStsPowerSupply2})) {
        $instance++;
        next if (!defined($value));
        my $psu_state = $value;

        next if ($self->check_filter(section => 'psu', instance => $instance));
        next if ($map_states_psu{$psu_state} eq 'notPresent' && 
                 $self->absent_problem(section => 'psu', instance => $instance));
        
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power Supply '%s' state is %s.",
                                    $instance, $map_states_psu{$psu_state}));
        my $exit = $self->get_severity(section => 'psu', value => $map_states_psu{$psu_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power Supply '%s' state is %s.", $instance, $map_states_psu{$psu_state}));
        }
    }
}


1;
