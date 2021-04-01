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

package storage::dell::me4::restapi::mode::components::sensor;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    $self->{json_results}->{sensors} = $self->{custom}->request_api(method => 'GET', url_path => '/api/show/sensor-status');
}

my %mapping = (
    'Voltage' => {
        unit => 'V',
        nlabel => 'voltage',
        nunit => 'volt',
        regexp => qr/(\d+)/
    },
    'Current' => {
        unit => 'A',
        nlabel => 'current',
        nunit => 'ampere',
        regexp => qr/(\d+)/
    },
    'Temperature' => {
        unit => 'C',
        nlabel => 'temperature',
        nunit => 'celsius',
        regexp => qr/(\d+)\sC/
    },
    'Charge Capacity' => {
        unit => '%',
        nlabel => 'capacity',
        nunit => 'percentage',
        regexp => qr/(\d+)%/
    },
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sensor'));
    return if (!defined($self->{json_results}->{sensors}));
    
    foreach my $result (@{$self->{json_results}->{sensors}->{sensors}}) {
        my $instance = $result->{'durable-id'};
        
        next if ($self->check_filter(section => 'sensor', instance => $instance));

        $self->{components}->{sensor}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Sensor '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{'sensor-name'}, $result->{status}, $instance,
                                    $result->{value}));
        
        my $exit1 = $self->get_severity(section => 'sensor', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit1, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit1,
                                        short_msg => sprintf("sensor '%s' status is '%s'", $result->{'sensor-name'}, $result->{status}));
        }
        
        next if (!defined($mapping{$result->{'sensor-type'}}));
        next if ($result->{value} !~ $mapping{$result->{'sensor-type'}}->{regexp});
        my $value = $1;
        my ($exit3, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'sensor', instance => $instance, value => $value);        
        if (!$self->{output}->is_status(value => $exit3, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit3,
                                        short_msg => sprintf("Sensor '%s' value is %s %s", $result->{'sensor-name'}, $value, $mapping{$result->{'sensor-type'}}->{nunit}));
        }
        $self->{output}->perfdata_add(
            label => 'sensor', unit => $mapping{$result->{'sensor-type'}}->{unit},
            nlabel => 'hardware.sensor.' . $mapping{$result->{'sensor-type'}}->{nlabel} . '.' . $mapping{$result->{'sensor-type'}}->{nunit},
            instances => $instance,
            value => $value,
            warning => $warn,
            critical => $crit, 
            min => 0
        );
    }
}

1;
