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

package storage::dell::me4::restapi::mode::components::psu;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    $self->{json_results}->{psus} = $self->{custom}->request_api(method => 'GET', url_path => '/api/show/power-supplies');
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    return if (!defined($self->{json_results}->{psus}));
    
    foreach my $result (@{$self->{json_results}->{psus}->{'power-supplies'}}) {
        my $instance = $result->{'durable-id'};
        
        next if ($self->check_filter(section => 'psu', instance => $instance));

        $self->{components}->{psu}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is '%s', health is '%s' [instance = %s]",
                                    $result->{name}, $result->{status}, $result->{health}, $instance));
        
        my $exit1 = $self->get_severity(section => 'psu', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit1, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit1,
                                        short_msg => sprintf("Power supply '%s' status is '%s'", $result->{name}, $result->{status}));
        }
        my $exit2 = $self->get_severity(section => 'psu', value => $result->{health});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Power supply '%s' health is '%s'", $result->{name}, $result->{health}));
        }
    }
}

1;
