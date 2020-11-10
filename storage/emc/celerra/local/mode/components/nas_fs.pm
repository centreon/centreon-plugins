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

package storage::emc::celerra::local::mode::components::nas_fs;

use strict;
use warnings;

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking nas_fs");
    $self->{components}->{nas_fs} = {name => 'nas_fs', total => 0, skip => 0};
    return if ($self->check_filter(section => 'nas_fs'));

    foreach my $line (split /\n/, $self->{stdout}) {
        next if ($line !~ /^server/);
        my ($dm, $vdm, $pool, $fs, $pctused, $maxsize) = split(/,/, $line);

        return if ($self->check_filter(section => 'nas_fs', fs => $fs));

        $self->{components}->{nas_fs}->{total}++;
        $self->{output}->output_add(long_msg => sprintf('FS %s as %d%% consumed', $fs, $pctused));
        my $exit = $self->get_severity_numeric(section => 'nas_fs', instance => $fs, value => $pctused);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit, short_msg => sprintf('FS %s as %d%% consumed', $fs, $pctused));
        }
    }
}

1;
