#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::cisco::cces::restapi::mode::components::temperature;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking temperature');
    $self->{components}->{temperature} = { name => 'temperature', total => 0, skip => 0 }  ;
    return if ($self->check_filter(section => 'temperature'));

    return if (!defined($self->{results}->{SystemUnit}->{Hardware}->{Monitoring}->{Temperature}));

    my $instance = 1;
    return if ($self->check_filter(section => 'temperature', instance => $instance));
    $self->{components}->{temperature}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            "temperature '%s' status is '%s' [instance: %s]",
            $instance,
            $self->{results}->{SystemUnit}->{Hardware}->{Monitoring}->{Temperature}->{Status},
            $instance
        )
    );

    my $exit = $self->get_severity(section => 'temperature', value => $self->{results}->{SystemUnit}->{Hardware}->{Monitoring}->{Temperature}->{Status});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf("temperarture '%s' status is '%s'", $instance, $self->{results}->{SystemUnit}->{Hardware}->{Monitoring}->{Temperature})
        );
    }
}

1;
