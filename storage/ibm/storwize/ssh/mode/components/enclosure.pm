#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package storage::ibm::storwize::ssh::mode::components::enclosure;

use strict;
use warnings;

sub load {
    my ($self) = @_;
    
    $self->{ssh_commands} .= 'echo "==========lsenclosure=========="; lsenclosure -delim : ; echo "===============";';
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking enclosures");
    $self->{components}->{enclosure} = {name => 'enclosures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'enclosure'));

    return if ($self->{results} !~ /==========lsenclosure==.*?\n(.*?)==============/msi);
    my $content = $1;
    
    my $result = $self->get_hasharray(content => $content, delim => ':');
    foreach (@$result) {
        next if ($self->check_filter(section => 'enclosure', instance => $_->{id}));
        $self->{components}->{enclosure}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("enclosure '%s' status is '%s' [instance: %s].",
                                    $_->{id}, $_->{status},
                                    $_->{id}
                                    ));
        my $exit = $self->get_severity(label => 'default', section => 'enclosure', value => $_->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Enclosure '%s' status is '%s'",
                                                             $_->{id}, $_->{status}));
        }
    }
}

1;