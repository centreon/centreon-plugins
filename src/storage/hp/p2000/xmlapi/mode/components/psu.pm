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

package storage::hp::p2000::xmlapi::mode::components::psu;

use strict;
use warnings;
use storage::hp::p2000::xmlapi::mode::components::resources qw($map_health);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    my ($entries, $rv) = $self->{custom}->get_infos(
        cmd => 'show power-supplies', 
        base_type => 'power-supplies',
        properties_name => '^durable-id|health-numeric|name$',
        no_quit => 1
    );
    return if ($rv == 0);

    my ($results, $duplicated) = ({}, {});
    foreach (@$entries) {
        my $name = $_->{name};
        $name = $_->{name} . ':' . $_->{'durable-id'} if (defined($duplicated->{$name}));
        if (defined($results->{$name})) {
            $duplicated->{$name} = 1;
            my $instance = $results->{$name}->{name} . ':' . $results->{$name}->{'durable-id'};
            $results->{$instance} = delete $results->{$name};
            $name = $_->{name} . ':' . $_->{'durable-id'};
        }
        $results->{$name} = $_;
    }

    foreach my $psu_id (sort keys %$results) {
        next if ($self->check_filter(section => 'psu', instance => $results->{$psu_id}->{'durable-id'}));
        $self->{components}->{psu}->{total}++;

        my $state = $map_health->{ $results->{$psu_id}->{'health-numeric'} };

        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' status is %s [instance: %s]",
                $psu_id, $state, $results->{$psu_id}->{'durable-id'}
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'psu', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Power supply '%s' status is '%s'", $psu_id, $state)
            );
        }
    }
}

1;
