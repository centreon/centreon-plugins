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

package centreon::common::broadcom::megaraid::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_temp_status = (
    1 => 'status-invalid', 2 => 'status-ok', 3 => 'status-critical', 4 => 'status-nonCritical', 
    5 => 'status-unrecoverable', 6 => 'status-not-installed', 7 => 'status-unknown', 8 => 'status-not-available'
);

my $mapping = {
    enclosureId_ETST => { oid => '.1.3.6.1.4.1.3582.4.1.5.6.1.2' },
    tempSensorStatus => { oid => '.1.3.6.1.4.1.3582.4.1.5.6.1.3', map => \%map_temp_status },
    enclosureTemperature => { oid => '.1.3.6.1.4.1.3582.4.1.5.6.1.4' },
};
my $oid_enclosureTempSensorEntry = '.1.3.6.1.4.1.3582.4.1.5.6.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_enclosureTempSensorEntry, start => $mapping->{enclosureId_ETST}->{oid}, 
        end => $mapping->{enclosureTemperature}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_enclosureTempSensorEntry}})) {
        next if ($oid !~ /^$mapping->{tempSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_enclosureTempSensorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        if ($result->{tempSensorStatus} =~ /status-not-installed/i) {
            $self->absent_problem(section => 'temperature', instance => $instance);
            next;
        }

        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' status is '%s' [instance = %s, enclosure = %s, temperature = %s C]",
                                                        $instance, $result->{tempSensorStatus}, $instance, $result->{enclosureId_ETST},
                                                        defined($result->{enclosureTemperature}) ? $result->{enclosureTemperature} : 'unknown'));
        $exit = $self->get_severity(section => 'default', value => $result->{tempSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $instance, $result->{tempSensorStatus}));
        }
        
        next if (!defined($result->{enclosureTemperature}) || $result->{enclosureTemperature} !~ /[0-9]+/);
        
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{enclosureTemperature});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' is '%s' C", $instance, $result->{enclosureTemperature}));
        }
        $self->{output}->perfdata_add(
            label => 'temp', unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $instance, 
            value => $result->{enclosureTemperature},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
