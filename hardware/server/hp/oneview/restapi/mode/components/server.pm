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

package hardware::server::hp::oneview::restapi::mode::components::server;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    push @{$self->{requests}}, { label => 'server', uri => '/rest/server-hardware?start=0&count=-1' };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking servers');
    $self->{components}->{server} = { name => 'server', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'server'));

    return if (!defined($self->{results}->{server}));

    foreach (@{$self->{results}->{server}->{members}}) {
        my $instance = $_->{serverName};
        
        next if ($self->check_filter(section => 'server', instance => $instance));
        $self->{components}->{server}->{total}++;

        my $status = $_->{status};
        $self->{output}->output_add(
            long_msg => sprintf(
                "server '%s' status is '%s' [instance = %s]",
                $instance, $status, $instance,
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'server', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Server '%s' status is '%s'", $instance, $status)
            );
        }
    }
}

1;
