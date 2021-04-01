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

package storage::hp::p2000::xmlapi::mode::components::fru;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking frus");
    $self->{components}->{fru} = {name => 'frus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fru'));
    
    my ($entries) = $self->{custom}->get_infos(
        cmd => 'show frus', 
        base_type => 'enclosure-fru',
        properties_name => '^fru-status|fru-location|oid$',
        no_quit => 1,
    );

    my ($results, $duplicated) = ({}, {});
    foreach (@$entries) {
        my $name = $_->{'fru-location'};
        $name = $_->{'fru-location'} . ':' . $_->{oid} if (defined($duplicated->{$name}));
        if (defined($results->{$name})) {
            $duplicated->{$name} = 1;
            my $instance = $results->{$name}->{'fru-location'} . ':' . $results->{$name}->{oid};
            $results->{$instance} = $results->{$name};
            delete $results->{$name};
            $name = $_->{'fru-location'} . ':' . $_->{oid};
        }
        $results->{$name} = $_;
    }

    foreach my $instance (keys %$results) {    
        next if ($self->check_filter(section => 'fru', instance => $instance));
        $self->{components}->{fru}->{total}++;
        
        my $state = $results->{$instance}->{'fru-status'};
        
        $self->{output}->output_add(
            long_msg => sprintf(
                "fru '%s' status is %s [instance: %s]",
                $instance, $state, $instance
            )
        );
        my $exit = $self->get_severity(section => 'fru', value => $state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Fru '%s' status is '%s'", $instance, $state)
            );
        }
    }
}

1;
