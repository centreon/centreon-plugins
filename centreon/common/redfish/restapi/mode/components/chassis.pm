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

package centreon::common::redfish::restapi::mode::components::chassis;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking chassis');
    $self->{components}->{chassis} = { name => 'chassis', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'chassis'));

    $self->get_chassis() if (!defined($self->{chassis}));

    foreach my $chassis (@{$self->{chassis}}) {
        my $instance = $chassis->{Id};
        
        next if ($self->check_filter(section => 'chassis', instance => $instance));
        $self->{components}->{chassis}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "chassis '%s' status is '%s' [instance: %s, state: %s]",
                $instance, $chassis->{Status}->{Health}, $instance, $chassis->{Status}->{State}
            )
        );

        my $exit = $self->get_severity(label => 'state', section => 'chassis.state', value => $chassis->{Status}->{State});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Chassis '%s' state is '%s'", $instance, $chassis->{Status}->{State})
            );
        }

        $exit = $self->get_severity(label => 'status', section => 'chassis.status', value => $chassis->{Status}->{Health});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Chassis '%s' status is '%s'", $instance, $chassis->{Status}->{Health})
            );
        }
    }
}

1;
