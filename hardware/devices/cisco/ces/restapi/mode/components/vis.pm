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

package hardware::devices::cisco::ces::restapi::mode::components::vis;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking video input sources');
    $self->{components}->{vis} = { name => 'video input sources', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'vis'));

    return if (!defined($self->{results}->{Video}->{Input}->{Source}));

    foreach (@{$self->{results}->{Video}->{Input}->{Source}}) {
        my $instance = $_->{item};

        next if ($self->check_filter(section => 'vis', instance => $instance));
        $self->{components}->{vis}->{total}++;

        my $format_status = defined($_->{Resolution}->{FormatStatus}) && ref($_->{Resolution}->{FormatStatus}) eq 'HASH' ? 
            $_->{Resolution}->{FormatStatus}->{content} :
            $_->{FormatStatus};

        $self->{output}->output_add(
            long_msg => sprintf(
                "video input source '%s' format status is '%s' [instance: %s]",
                $instance,
                $format_status,
                $instance
            )
        );

        my $exit = $self->get_severity(section => 'format_status', value => $format_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("video input source '%s' format status is '%s'", $instance, $format_status)
            );
        }
    }
}

1;
