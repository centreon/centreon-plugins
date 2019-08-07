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
# Author : ArnoMLT
#

package network::atto::fibrebridge::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_chassis_status = (
    1 => 'normal', 2 => 'warning', 3 => 'critical', 
);
my $oid_chassisTemperatureStatus = '.1.3.6.1.4.1.4547.2.3.2.9.0';
my $oid_chassisTemperature = '.1.3.6.1.4.1.4547.2.3.2.8.0';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, $oid_chassisTemperatureStatus, $oid_chassisTemperature;
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    return if (!defined($self->{results}->{$oid_chassisTemperatureStatus}));
    my ($instance, $name) = (1, 'chassis');
    my $status = $map_chassis_status{$self->{results}->{$oid_chassisTemperatureStatus}};
    my $temperature = $self->{results}->{$oid_chassisTemperature};
        
    next if ($self->check_filter(section => 'temperature', instance => $instance, name => $name));
    $self->{components}->{temperature}->{total}++;
    
    $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is %s [instance = %s, value = %s C]", 
                                    $name, $status, $instance, $temperature));
    my $exit = $self->get_severity(section => 'temperature', value => $status);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Temperature '%s' status is %s", $name, $status));
    }
            
    my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => $instance, name => $name, value => $temperature);
    if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit2,
                                    short_msg => sprintf("Temperature '%s' is %s C", $name, $temperature));
    }
    $self->{output}->perfdata_add(
        label => 'temp', unit => 'C',
        nlabel => 'hardware.temperature.celsius',
        instances => $name,
        value => $temperature,
        warning => $warn,
        critical => $crit
    );
}

1;
