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

package storage::netgear::readynas::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    v6 => {
        temperatureValue => { oid => '.1.3.6.1.4.1.4526.22.5.1.2' },
        temperatureType => { oid => '.1.3.6.1.4.1.4526.22.5.1.3' },
        temperatureMax => { oid => '.1.3.6.1.4.1.4526.22.5.1.5' },
    },
    v4 => {
        temperatureValue => { oid => '.1.3.6.1.4.1.4526.18.5.1.2' },
        temperatureStatus => { oid => '.1.3.6.1.4.1.4526.18.5.1.3' },
    },
};
my $oid_temperatureTable = {
    v4 => '.1.3.6.1.4.1.4526.18.5',
    v6 => '.1.3.6.1.4.1.4526.22.5',
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_temperatureTable->{$self->{mib_ver}}, 
        start => $mapping->{$self->{mib_ver}}->{temperatureValue} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $oid_temperatureTable->{$self->{mib_ver}} }})) {
        next if ($oid !~ /^$mapping->{$self->{mib_ver}}->{temperatureValue}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping->{$self->{mib_ver}}, results => $self->{results}->{ $oid_temperatureTable->{$self->{mib_ver}} }, instance => $instance);
        $instance .= "_" . $result->{temperatureType} if (defined($result->{temperatureType}));
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;
        
        my $temperatureMax_string = defined($result->{temperatureMax}) && $result->{temperatureMax} != -1 ? "  ($result->{temperatureMax} max)" : '';
        my $temperatureMax_unit = defined($result->{temperatureMax}) && $self->{mib_ver} == 6 ? 'C' : 'F';
        
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is %s [value = %s%s]", 
                                        $instance, $result->{temperatureStatus}, $result->{temperatureValue}, $temperatureMax_unit));
        my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{temperatureStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is %s.", $instance, $result->{temperatureStatus}));
        }
                
        my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{temperatureValue});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Temperature '%s' is %s%s", $instance, $result->{temperatureValue}, $temperatureMax_unit));
        }
        $self->{output}->perfdata_add(
            label => 'temp', unit => $temperatureMax_unit,
            nlabel => 'hardware.temperature.' . (($temperatureMax_unit eq 'C') ? 'celsius' : 'fahrenheit'),
            instances => $instance,
            value => $result->{temperatureValue},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
