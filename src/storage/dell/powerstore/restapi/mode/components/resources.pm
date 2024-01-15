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

package storage::dell::powerstore::restapi::mode::components::resources;

use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(check_component);

sub check_component {
    my ($self, %options) = @_;

    if (!defined($self->{components}->{ $options{label} })) {
        $self->{output}->output_add(long_msg => 'checking ' . $options{label});
        $self->{components}->{ $options{label} } = { name => $options{label}, total => 0, skip => 0 };
    }
    return if ($self->check_filter(section => $options{label}));

    foreach my $entry (@{$self->{results}}) {
        next if (!defined($entry->{type}) || $entry->{type} ne $options{component});
        next if (!defined($entry->{lifecycle_state}));
        my $instance = $entry->{id};

        next if ($self->check_filter(section => $options{label}, instance => $instance));
        next if ($entry->{lifecycle_state} =~ /empty/i &&
            $self->absent_problem(section => $options{label}, instance => $instance));

        $self->{components}->{ $options{label} }->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "%s '%s' status is '%s' [instance: %s]",
                $options{label}, $entry->{name}, $entry->{lifecycle_state}, $instance,
            )
        );

        my $exit = $self->get_severity(label => 'default', section => $options{label}, value => $entry->{lifecycle_state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("%s '%s' status is '%s'", $options{label}, $entry->{name}, $entry->{lifecycle_state})
            );
        }
    }
}

1;
