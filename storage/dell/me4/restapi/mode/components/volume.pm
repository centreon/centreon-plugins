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

package storage::dell::me4::restapi::mode::components::volume;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    $self->{json_results}->{volumes} = $self->{custom}->request_api(method => 'GET', url_path => '/api/show/volumes');
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking volumes");
    $self->{components}->{volume} = {name => 'volumes', total => 0, skip => 0};
    return if ($self->check_filter(section => 'volume'));
    return if (!defined($self->{json_results}->{volumes}));
    
    foreach my $result (@{$self->{json_results}->{volumes}->{volumes}}) {
        my $instance = $result->{'durable-id'};
        
        next if ($self->check_filter(section => 'volume', instance => $instance));

        $self->{components}->{volume}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Volume '%s' health is '%s' [instance = %s]",
                                    $result->{'volume-name'}, $result->{health}, $instance));
        
        my $exit1 = $self->get_severity(section => 'volume', value => $result->{health});
        if (!$self->{output}->is_status(value => $exit1, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit1,
                                        short_msg => sprintf("Volume '%s' health is '%s'", $result->{'volume-name'}, $result->{health}));
        }
    }
}

1;
