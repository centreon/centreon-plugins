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

package network::extreme::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    extremeCurrentTemperature => { oid => '.1.3.6.1.4.1.1916.1.1.1.8' },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{extremeCurrentTemperature}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'Checking temperatures');
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));
    
    return if (!defined($self->{results}->{$mapping->{extremeCurrentTemperature}->{oid}}->{$mapping->{extremeCurrentTemperature}->{oid} . '.0'}));
    my $instance = 0;
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{extremeCurrentTemperature}->{oid}}, instance => $instance);
        
    next if ($self->check_filter(section => 'temperature', instance => $instance));
    $self->{components}->{temperature}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            'temperature is %dC [instance: %s].',
            $result->{extremeCurrentTemperature},
            $instance
        )
    );
    my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{extremeCurrentTemperature});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                'Temperature is %s degree centigrade',
                $result->{extremeCurrentTemperature}
            )
        );
    }

    $self->{output}->perfdata_add(
        label => 'temp', unit => 'C',
        nlabel => 'hardware.temperature.celsius',
        value => $result->{extremeCurrentTemperature},
        warning => $warn,
        critical => $crit
    );
}

1;
