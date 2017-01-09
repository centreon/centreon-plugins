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

package storage::qnap::snmp::mode::components::temperature;

use strict;
use warnings;

# In MIB 'NAS.mib'
my $oid_CPU_Temperature_entry = '.1.3.6.1.4.1.24681.1.2.5';
my $oid_CPU_Temperature = '.1.3.6.1.4.1.24681.1.2.5.0';
my $oid_SystemTemperature_entry = '.1.3.6.1.4.1.24681.1.2.6';
my $oid_SystemTemperature = '.1.3.6.1.4.1.24681.1.2.6.0';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_CPU_Temperature_entry }, { oid => $oid_SystemTemperature_entry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    my $cpu_temp = defined($self->{results}->{$oid_CPU_Temperature_entry}->{$oid_CPU_Temperature}) ? 
                           $self->{results}->{$oid_CPU_Temperature_entry}->{$oid_CPU_Temperature} : 'unknown';
    if ($cpu_temp =~ /([0-9]+)\s*C/ && !$self->check_filter(section => 'temperature', instance => 'cpu')) {
        my $value = $1;
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("CPU Temperature is '%s' degree centigrade",
                                                        $value));
        my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => 'cpu', value => $value);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("CPU Temperature is '%s' degree centigrade", $value));
        }
        $self->{output}->perfdata_add(label => 'temp_cpu', unit => 'C',
                                      value => $value
                                      );
    }
    
    my $system_temp = defined($self->{results}->{$oid_SystemTemperature_entry}->{$oid_SystemTemperature}) ? 
                           $self->{results}->{$oid_SystemTemperature_entry}->{$oid_SystemTemperature} : 'unknown';
    if ($system_temp =~ /([0-9]+)\s*C/ && !$self->check_filter(section => 'temperature', instance => 'system')) {
        my $value = $1;
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("System Temperature is '%s' degree centigrade",
                                                        $value));
        my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => 'system', value => $value);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("System Temperature is '%s' degree centigrade", $value));
        }
        $self->{output}->perfdata_add(label => 'temp_system', unit => 'C',
                                      value => $value
                                      );
    }
}

1;