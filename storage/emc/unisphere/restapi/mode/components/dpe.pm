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

package storage::emc::unisphere::restapi::mode::components::dpe;

use strict;
use warnings;
use storage::emc::unisphere::restapi::mode::components::resources qw($health_status);

sub load {
    my ($self) = @_;

    $self->{json_results}->{dpe} = $self->{custom}->request_api(method => 'GET', url_path => '/api/types/dpe/instances?fields=name,health,currentPower,currentTemperature');
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking disk processor enclosures');
    $self->{components}->{dpe} = { name => 'dpe', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'dpe'));
    return if (!defined($self->{json_results}->{dpe}));

    foreach my $result (@{$self->{json_results}->{dpe}->{entries}}) {
        my $instance = $result->{content}->{id};

        next if ($self->check_filter(section => 'dpe', instance => $instance));
        $self->{components}->{dpe}->{total}++;

        my $health = $health_status->{ $result->{content}->{health}->{value} };
        $self->{output}->output_add(
            long_msg => sprintf(
                "dpe '%s' status is '%s' [instance = %s]",
                $result->{content}->{name}, $health, $instance,
            )
        );
        
        my $exit = $self->get_severity(label => 'health', section => 'dpe', value => $health);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("dpe '%s' status is '%s'", $result->{content}->{name}, $health)
            );
        }

        if (defined($result->{content}->{currentTemperature}) && $result->{content}->{currentTemperature} =~ /[0-9]/) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{content}->{currentTemperature});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf("dpe '%s' temperature is %s C", $result->{content}->{name}, $result->{content}->{currentTemperature})
                );
            }
            $self->{output}->perfdata_add(
                nlabel => 'hardware.dpe.temperature.celsius', unit => 'C',
                instances => $result->{content}->{name},
                value => $result->{content}->{currentTemperature},
                warning => $warn,
                critical => $crit,
            );
        }

        if (defined($result->{content}->{currentPower}) && $result->{content}->{currentPower} =~ /[0-9]/) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'power', instance => $instance, value => $result->{content}->{currentPower});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf("dpe '%s' current power is %s W", $result->{content}->{name}, $result->{content}->{currentPower})
                );
            }
            $self->{output}->perfdata_add(
                nlabel => 'hardware.dpe.power.watt', unit => 'W',
                instances => $result->{content}->{name},
                value => $result->{content}->{currentPower},
                warning => $warn,
                critical => $crit,
            );
        }
    }
}

1;
