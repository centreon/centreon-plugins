#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package storage::hp::p2000::xmlapi::mode::components::fan;

use strict;
use warnings;
use storage::hp::p2000::xmlapi::mode::components::resources qw($map_health);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = { name => 'fan', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    my ($entries, $rv) = $self->{custom}->get_infos(
        cmd => 'show fans', 
        base_type => 'fan',
        properties_name => '^health-numeric|location|durable-id|speed$',
        no_quit => 1
    );
    return if ($rv == 0);

    my ($results, $duplicated) = ({}, {});
    foreach (@$entries) {
        my $name = $_->{location};
        $name = $_->{location} . ':' . $_->{'durable-id'} if (defined($duplicated->{$name}));
        if (defined($results->{$name})) {
            $duplicated->{$name} = 1;
            my $instance = $results->{$name}->{location} . ':' . $results->{$name}->{'durable-id'};
            $results->{$instance} = delete $results->{$name};
            $name = $_->{location} . ':' . $_->{'durable-id'};
        }
        $results->{$name} = $_;
    }

    foreach my $instance (sort keys %$results) {
        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        my $state = $map_health->{  $results->{$instance}->{'health-numeric'} };
        my $speed = $results->{$instance}->{speed};

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is %s [instance: %s, speed: %s]",
                $instance,
                $state,
                $instance,
                defined($speed) ? $speed : '-'
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'fan', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Fan '%s' status is '%s'", $instance, $state)
            );
        }

        next if (!defined($speed));

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan.speed', instance => $instance, value => $speed);
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf("Fan '%s' speed is %s rpm", $instance, $speed)
            );
        }

        $self->{output}->perfdata_add(
            nlabel => 'hardware.fan.speed.rpm',
            unit => 'rpm',
            instances => $instance,
            value => $speed,
            warning => $warn,
            critical => $crit
        );
    }
}

1;
