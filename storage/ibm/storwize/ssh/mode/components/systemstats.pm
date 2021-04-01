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

package storage::ibm::storwize::ssh::mode::components::systemstats;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    $self->{ssh_commands} .= 'echo "==========lssystemstats=========="; lssystemstats ; echo "===============";';
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking systemstats");
    $self->{components}->{systemstats} = {name => 'systemstats', total => 0, skip => 0};
    return if ($self->check_filter(section => 'systemstats'));

    return if ($self->{results} !~ /==========lssystemstats==.*?\n(.*?)==============/msi);
    my $content = $1;

    my $result = $self->{custom}->get_hasharray(content => $content, delim => '\s+');
    foreach (@$result) {
        next if ($self->check_filter(section => 'systemstats', instance => $_->{stat_name}));
        $self->{components}->{systemstats}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "system stat '%s' value is '%s' [instance: %s].",
                $_->{stat_name},
                $_->{stat_current},
                $_->{stat_name}
            )
        );
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'systemstats', instance => $_->{stat_name}, value => $_->{stat_current});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "System stat '%s' value is '%s'", $_->{stat_name}, $_->{stat_current}
                )
            );
        }
        $self->{output}->perfdata_add(
            label => "sstat",
            nlabel => 'hardware.systemstats.current.count',
            instances => $_->{stat_name},
            value => $_->{stat_current},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
