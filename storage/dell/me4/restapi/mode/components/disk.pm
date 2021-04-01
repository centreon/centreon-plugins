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

package storage::dell::me4::restapi::mode::components::disk;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    $self->{json_results}->{disks} = $self->{custom}->request_api(method => 'GET', url_path => '/api/show/disks');
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'disk'));
    return if (!defined($self->{json_results}->{disks}));
    
    foreach my $result (@{$self->{json_results}->{disks}->{drives}}) {
        my $instance = $result->{'durable-id'};
        
        next if ($self->check_filter(section => 'disk', instance => $instance));

        $self->{components}->{disk}->{total}++;
        
        $self->{output}->output_add(
            long_msg => sprintf(
                "Disk '%s' status is '%s', health is '%s', state is '%s' [instance = %s] [temperature = %s C]",
                $result->{'serial-number'}, $result->{status}, $result->{health}, $result->{state}, $instance,
                $result->{'temperature-numeric'}
            )
        );

        my $exit1 = $self->get_severity(section => 'disk', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit1, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit1,
                short_msg => sprintf(
                    "Disk '%s' status is '%s'",
                    $result->{'serial-number'},
                    $result->{status}
                )
            );
        }
        my $exit2 = $self->get_severity(section => 'disk', value => $result->{health});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Disk '%s' health is '%s'",
                    $result->{'serial-number'},
                    $result->{health}
                )
            );
        }
        my $exit3 = $self->get_severity(section => 'disk', value => $result->{state});
        if (!$self->{output}->is_status(value => $exit3, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit3,
                short_msg => sprintf(
                    "Disk '%s' state is '%s'",
                    $result->{'serial-number'},
                    $result->{state}
                )
            );
        }
        
        next if ($result->{'temperature-numeric'} !~ /[0-9]/);
        my ($exit4, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'disk', instance => $instance, value => $result->{'temperature-numeric'});        
        if (!$self->{output}->is_status(value => $exit4, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit4,
                short_msg => sprintf(
                    "Disk '%s' temperature is %s C",
                    $result->{'serial-number'},
                    $result->{'temperature-numeric'}
                )
            );
        }
        $self->{output}->perfdata_add(
            label => 'temperature', unit => 'C',
            nlabel => 'hardware.disk.temperature.celsius',
            instances => $instance,
            value => $result->{'temperature-numeric'},
            warning => $warn,
            critical => $crit, 
            min => 0
        );
    }
}

1;
