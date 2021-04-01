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

package hardware::server::dell::openmanage::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_status = (
    1 => 'other',
    2 => 'unknown',
    3 => 'ok',
    4 => 'nonCriticalUpper',
    5 => 'criticalUpper',
    6 => 'nonRecoverableUpper',
    7 => 'nonCriticalLower',
    8 => 'criticalLower',
    9 => 'nonRecoverableLower',
    10 => 'failed',
);
my %map_type = (
    1 => 'other',
    2 => 'unknown',
    3 => 'Ambient ESM',
    4 => 'Discrete',
);

# In MIB '10892.mib'
my $mapping = {
    temperatureProbeStatus => { oid => '.1.3.6.1.4.1.674.10892.1.700.20.1.5', map => \%map_status },
    temperatureProbeReading => { oid => '.1.3.6.1.4.1.674.10892.1.700.20.1.6' },
    temperatureProbeType => { oid => '.1.3.6.1.4.1.674.10892.1.700.20.1.7', map => \%map_type },
    temperatureProbeLocationName => { oid => '.1.3.6.1.4.1.674.10892.1.700.20.1.8' },
};
my $oid_temperatureProbeTable = '.1.3.6.1.4.1.674.10892.1.700.20';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_temperatureProbeTable, start => $mapping->{temperatureProbeStatus}->{oid}, end => $mapping->{temperatureProbeLocationName}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_temperatureProbeTable}})) {
        next if ($oid !~ /^$mapping->{temperatureProbeStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_temperatureProbeTable}, instance => $instance);

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' status is '%s' [instance: %s, location: %s, reading: %s]",
                                    $instance, $result->{temperatureProbeStatus}, $instance, 
                                    $result->{temperatureProbeLocationName}, $result->{temperatureProbeReading}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{temperatureProbeStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'",
                                           $instance, $result->{temperatureProbeStatus}));
        }
        
        if (defined($result->{temperatureProbeReading}) && $result->{temperatureProbeReading} =~ /[0-9]/) {
            $result->{temperatureProbeReading} /= 10;
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{temperatureProbeReading});
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Temperature '%s' is %s degree centigrade", $instance, $result->{temperatureProbeReading}));
            }
            $self->{output}->perfdata_add(
                label => 'temp', unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => $instance,
                value => $result->{temperatureProbeReading},
                warning => $warn,
                critical => $crit,
                min => 0
            );
        }
    }
}

1;
