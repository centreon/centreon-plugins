#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::mikrotik::snmp::mode::components::voltage;

use strict;
use warnings;

my $mapping = {
    mtxrHlVoltage => { oid => '.1.3.6.1.4.1.14988.1.1.3.8' },
};

my $oid_mtxrHealth = '.1.3.6.1.4.1.14988.1.1.3';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_mtxrHealth };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltage");
    $self->{components}->{voltage} = {name => 'voltage', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));
    
    my $instance = 0;
    my ($exit, $warn, $crit, $checked);
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_mtxrHealth}, instance => $instance);
    
    if (defined($result->{mtxrHlVoltage}) && $result->{mtxrHlVoltage} =~ /[0-9]+/) {
        
        $self->{output}->output_add(long_msg => sprintf("Voltage is '%s' V", $result->{mtxrHlVoltage} / 10));

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{mtxrHlVoltage} / 10);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage is '%s' V", $result->{mtxrHlVoltage} / 10));
        }
        $self->{output}->perfdata_add(label => 'voltage', unit => 'V', 
                                      value => $result->{mtxrHlVoltage} / 10,
                                      warning => $warn,
                                      critical => $crit);
        $self->{components}->{voltage}->{total}++;
    }
}

1;
