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

package hardware::server::fujitsu::snmp::mode::components::temperature;

use strict;
use warnings;

my $map_sc_temp_status = {
    1 => 'unknown', 2 => 'sensor-disabled', 3 => 'ok', 4 => 'sensor-fail',
    5 => 'warning-temp-warm', 6 => 'warning-temp-cold', 7 => 'critical-temp-warm',
    8 => 'critical-temp-cold', 9 => 'damage-temp-warm', 10 => 'damage-temp-cold', 99 => 'not-available',
};
my $map_sc2_temp_status = {
    1 => 'unknown', 2 => 'not-available', 3 => 'ok', 4 => 'sensor-failed', 5 => 'failed',
    6 => 'temperature-warning-toohot', 7 => 'temperature-critical-toohot', 8 => 'temperature-normal',
    9 => 'temperature-warning',
};

my $mapping = {
    sc => {
        tempSensorStatus        => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.2.1.1.3', map => $map_sc_temp_status },
        tempCurrentValue        => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.2.1.1.11' },
        tempSensorDesignation   => { oid => '.1.3.6.1.4.1.231.2.10.2.2.5.2.1.1.13' },
    },
    sc2 => {
        sc2tempSensorDesignation    => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.5.1.1.3' },
        sc2tempSensorStatus         => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.5.1.1.5', map => $map_sc2_temp_status },
        sc2tempCurrentTemperature   => { oid => '.1.3.6.1.4.1.231.2.10.2.2.10.5.1.1.6' },
    },
};
my $oid_sc2TemperatureSensors = '.1.3.6.1.4.1.231.2.10.2.2.10.5.1.1';
my $oid_temperatureSensors = '.1.3.6.1.4.1.231.2.10.2.2.5.2.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_sc2TemperatureSensors, end => $mapping->{sc2}->{sc2tempCurrentTemperature} }, { oid => $oid_temperatureSensors };
}

sub check_temperature {
    my ($self, %options) = @_;

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$options{entry}}})) {
        next if ($oid !~ /^$options{mapping}->{$options{status}}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{$options{entry}}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        next if ($result->{$options{status}} =~ /not-present|not-available/i &&
                 $self->absent_problem(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{$options{name}}, $result->{$options{status}}, $instance, $result->{$options{current}}
                                    ));

        $exit = $self->get_severity(section => 'temperature', value => $result->{$options{status}});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $result->{$options{name}}, $result->{$options{status}}));
        }
     
        next if (!defined($result->{$options{current}}) || $result->{$options{current}} <= 0 || $result->{$options{current}} == 255);
     
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{$options{current}});
        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' is %s V", $result->{$options{name}}, $result->{$options{current}}));
        }
        $self->{output}->perfdata_add(
            label => 'temperature', unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $result->{$options{name}},
            value => $result->{$options{current}},
            warning => $warn,
            critical => $crit,
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    if (defined($self->{results}->{$oid_sc2TemperatureSensors}) && scalar(keys %{$self->{results}->{$oid_sc2TemperatureSensors}}) > 0) {
        check_temperature($self, entry => $oid_sc2TemperatureSensors, mapping => $mapping->{sc2}, name => 'sc2tempSensorDesignation',
            current => 'sc2tempCurrentTemperature', status => 'sc2tempSensorStatus');
    } else {
        check_temperature($self, entry => $oid_temperatureSensors, mapping => $mapping->{sc}, name => 'tempSensorDesignation', 
            current => 'tempCurrentValue', status => 'tempSensorStatus');
    }
}

1;
