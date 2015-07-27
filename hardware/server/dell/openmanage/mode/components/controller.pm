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

package hardware::server::dell::openmanage::mode::components::controller;

use strict;
use warnings;

my %state = (
    0 => 'unknown',
    1 => 'ready', 
    2 => 'failed', 
    3 => 'online', 
    4 => 'offline',
    6 => 'degraded',
);

my %status = (
    1 => ['other', 'UNKNOWN'],
    2 => ['unknown', 'UNKNOWN'],
    3 => ['ok', 'OK'],
    4 => ['nonCritical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'CRITICAL'],
);

sub check {
    my ($self) = @_;

    # In MIB '10893.mib'
    $self->{output}->output_add(long_msg => "Checking Controllers");
    $self->{components}->{controller} = {name => 'controllers', total => 0};
    return if ($self->check_exclude('controller'));
   
    my $oid_controllerName = '.1.3.6.1.4.1.674.10893.1.20.130.1.1.2';
    my $oid_controllerState = '.1.3.6.1.4.1.674.10893.1.20.130.1.1.5';
    my $oid_controllerComponentStatus = '.1.3.6.1.4.1.674.10893.1.20.130.1.1.38';
    my $oid_controllerFWVersion = '.1.3.6.1.4.1.674.10893.1.20.130.1.1.8';

    my $result = $self->{snmp}->get_table(oid => $oid_controllerName);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_controllerState, $oid_controllerComponentStatus, $oid_controllerFWVersion],
                        instances => [keys %$result],
                        instance_regexp => '(\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $controller_Index = $1;
        
        my $controller_name = $result->{$key};
        my $controller_state = $result2->{$oid_controllerState . '.' . $controller_Index};
        my $controller_componentStatus = $result2->{$oid_controllerComponentStatus . '.' . $controller_Index};
        my $controller_FWVersion = $result2->{$oid_controllerFWVersion . '.' . $controller_Index};
        
        $self->{components}->{controller}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("controller '%s' status is '%s', state is '%s' [index: %d, firmware: %s].",
                                    $controller_name, ${$status{$controller_componentStatus}}[0], $state{$controller_state},
                                    $controller_Index, $controller_FWVersion
                                    ));

        if ($controller_componentStatus != 3) {
            $self->{output}->output_add(severity =>  ${$status{$controller_componentStatus}}[1],
                                        short_msg => sprintf("controller '%s' status is '%s' [index: %d]",
                                           $controller_name, ${$status{$controller_componentStatus}}[0], $controller_Index));
        }

    }
}

1;
