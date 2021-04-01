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

package storage::emc::unisphere::restapi::mode::components::sp;

use strict;
use warnings;
use storage::emc::unisphere::restapi::mode::components::resources qw($health_status);

sub load {
    my ($self) = @_;

    $self->{json_results}->{sp} = $self->{custom}->request_api(method => 'GET', url_path => '/api/types/storageProcessor/instances?fields=health');
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking storage processors');
    $self->{components}->{sp} = { name => 'sp', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'sp'));
    return if (!defined($self->{json_results}->{sp}));

    foreach my $result (@{$self->{json_results}->{sp}->{entries}}) {
        my $instance = $result->{content}->{id};

        next if ($self->check_filter(section => 'sp', instance => $instance));
        $self->{components}->{sp}->{total}++;

        my $health = $health_status->{ $result->{content}->{health}->{value} };
        $self->{output}->output_add(
            long_msg => sprintf(
                "storage processor '%s' status is '%s' [instance = %s]",
                $result->{content}->{name}, $health, $instance,
            )
        );
        
        my $exit = $self->get_severity(label => 'health', section => 'sp', value => $health);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Storage processor '%s' status is '%s'", $result->{content}->{name}, $health)
            );
        }
    }
}

1;
