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

package storage::emc::DataDomain::mode::components::temperature;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_temp_status = ();
my ($oid_tempSensorDescription, $oid_tempSensorCurrentValue, $oid_tempSensorStatus);
my $oid_temperatureSensorEntry = '.1.3.6.1.4.1.19746.1.1.2.1.1.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_temperatureSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_tempSensorDescription = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.4';
        $oid_tempSensorCurrentValue = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.5';
        $oid_tempSensorStatus = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.6';
        %map_temp_status = (0 => 'failed', 1 => 'ok', 2 => 'notfound', 3 => 'overheatWarning',
                            4 => 'overheatCritical');
    } else {
        $oid_tempSensorDescription = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.3';
        $oid_tempSensorCurrentValue = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.4';
        $oid_tempSensorStatus = '.1.3.6.1.4.1.19746.1.1.2.1.1.1.5';
        %map_temp_status = (0 => 'absent', 1 => 'ok', 2 => 'notfound');
    }

    foreach my $oid (keys %{$self->{results}->{$oid_temperatureSensorEntry}}) {
        next if ($oid !~ /^$oid_tempSensorStatus\.(.*)$/);
        my $instance = $1;
        my $temp_descr = defined($self->{results}->{$oid_temperatureSensorEntry}->{$oid_tempSensorDescription . '.' . $instance}) ? 
                            centreon::plugins::misc::trim($self->{results}->{$oid_temperatureSensorEntry}->{$oid_tempSensorDescription . '.' . $instance}) : 'unknown';
        my $temp_status = defined($map_temp_status{$self->{results}->{$oid_temperatureSensorEntry}->{$oid}}) ?
                            $map_temp_status{$self->{results}->{$oid_temperatureSensorEntry}->{$oid}} : 'unknown';
        my $temp_value = $self->{results}->{$oid_temperatureSensorEntry}->{$oid_tempSensorCurrentValue . '.' . $instance};

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        next if ($temp_status =~ /absent|notfound/i && 
                 $self->absent_problem(section => 'temperature', instance => $instance));
        
        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' status is '%s' [instance = %s]",
                                    $temp_descr, $temp_status, $instance));
        my $exit = $self->get_severity(section => 'temperature', value => $temp_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $temp_descr, $temp_status));
        }

        if (defined($temp_value) && $temp_value =~ /[0-9]/) {
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $temp_value);
            $self->{output}->output_add(long_msg => sprintf("Temperature '%s' is %s degree centigrade", $temp_descr, $temp_value));
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Temperature '%s' is %s degree centigrade", $temp_descr, $temp_value));
            }
            $self->{output}->perfdata_add(
                label => 'temp', unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => $instance,
                value => $temp_value,
                warning => $warn,
                critical => $crit,
            );
        }
    }
}

1;
