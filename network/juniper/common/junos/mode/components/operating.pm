#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::mode::components::operating;

use strict;
use warnings;

my %map_operating_states = (
    1 => 'unknown', 
    2 => 'running', 
    3 => 'ready', 
    4 => 'reset',
    5 => 'runningAtFullSpeed',
    6 => 'down',
    7 => 'standby',
);

# In MIB 'mib-jnx-chassis'
my $mapping = {
    jnxOperatingDescr => { oid => '.1.3.6.1.4.1.2636.3.1.13.1.5' },
    jnxOperatingState => { oid => '.1.3.6.1.4.1.2636.3.1.13.1.6', map => \%map_operating_states },
};
my $oid_jnxOperatingEntry = '.1.3.6.1.4.1.2636.3.1.13.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_jnxOperatingEntry, start => $mapping->{jnxOperatingDescr}->{oid}, end => $mapping->{jnxOperatingState}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking operatings");
    $self->{components}->{operating} = {name => 'operatings', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'operating'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_jnxOperatingEntry}})) {
        next if ($oid !~ /^$mapping->{jnxOperatingDescr}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_jnxOperatingEntry}, instance => $instance);
        
        next if ($self->check_exclude(section => 'operating', instance => $instance));
        $self->{components}->{operating}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Operating '%s' state is %s [instance: %s]", 
                                                        $result->{jnxOperatingDescr}, $result->{jnxOperatingState}, $instance));
        my $exit = $self->get_severity(section => 'operating', value => $result->{jnxOperatingState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Operating '%s' state is %s", 
                                    $result->{jnxOperatingDescr}, $result->{jnxOperatingState}));
        }
    }
}

1;