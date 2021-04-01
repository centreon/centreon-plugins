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

package hardware::server::dell::openmanage::snmp::mode::components::controller;

use strict;
use warnings;

my %map_state = (
    0 => 'unknown',
    1 => 'ready', 
    2 => 'failed', 
    3 => 'online', 
    4 => 'offline',
    6 => 'degraded',
);
my %map_status = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCritical',
    5 => 'critical',
    6 => 'nonRecoverable',
);

# In MIB 'dcstorag.mib'
my $mapping = {
    controllerName => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.1.1.2' },
};
my $mapping2 = {
    controllerComponentStatus => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.1.1.38', map => \%map_status },
};
my $mapping3 = {
    controllerState => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.1.1.5', map => \%map_state },
};
my $mapping4 = {
    controllerFWVersion => { oid => '.1.3.6.1.4.1.674.10893.1.20.130.1.1.8' },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{controllerName}->{oid} }, { oid => $mapping2->{controllerComponentStatus}->{oid} },
        { oid => $mapping3->{controllerState}->{oid} }, { oid => $mapping4->{controllerFWVersion}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking controllers");
    $self->{components}->{controller} = {name => 'controllers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'controller'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping2->{controllerComponentStatus}->{oid}}})) {
        next if ($oid !~ /^$mapping2->{controllerComponentStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{controllerName}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{controllerComponentStatus}->{oid}}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$mapping3->{controllerState}->{oid}}, instance => $instance);
        my $result4 = $self->{snmp}->map_instance(mapping => $mapping4, results => $self->{results}->{$mapping4->{controllerFWVersion}->{oid}}, instance => $instance);

        next if ($self->check_filter(section => 'controller', instance => $instance));
        
        $self->{components}->{controller}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Controller '%s' status is '%s' [instance: %s, state: %s, firmware: %s]",
                                    $result->{controllerName}, $result2->{controllerComponentStatus}, $instance, 
                                    $result3->{controllerState}, $result4->{controllerFWVersion}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'controller', value => $result2->{controllerComponentStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Controller '%s' status is '%s'",
                                           $result->{controllerName}, $result2->{controllerComponentStatus}));
        }
    }
}

1;
