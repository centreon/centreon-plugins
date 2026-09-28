#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package centreon::common::redfish::restapi::mode::components::drive;

use strict;
use warnings;
use centreon::plugins::misc qw(value_of);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking drives');
    $self->{components}->{drive} = { name => 'drives', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'drive'));

    $self->get_storages() if (!defined($self->{storages}));

    foreach my $storage (@{$self->{storages}}) {
        $storage->{'@odata.id'} =~ /Systems\/([^\/]+)\//;
        my $system_id = $1;
        my $system_name = 'system:' . $system_id;

        my $storage_name = $storage->{Id};

        foreach (@{$storage->{Drives}}) {
            my $drive = $self->get_drive(drive => $_);

            my $instance = $system_id . '.' . $storage->{Id} . '.' . $drive->{Id};

            $drive->{Status}->{Health} = value_of($drive, '->{Status}->{Health}', 'n/a');
            $drive->{Status}->{State} = value_of($drive, '->{Status}->{State}', 'n/a');
            my $location = value_of($drive, '->{PhysicalLocation}->{PartLocation}->{ServiceLabel}', 'n/a');
            next if ($self->check_filter(section => 'drive', instance => $instance));
            $self->{components}->{drive}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "drive '%s/%s/%s' status is '%s' [instance: %s, state: %s, location: %s]",
                    $system_name,
                    $storage_name,
                    $drive->{Id},
                    $drive->{Status}->{Health},
                    $instance,
                    $drive->{Status}->{State},
                    $location
                )
            );

            my $exit = $self->get_severity(label => 'state', section => 'drive.state', value => $drive->{Status}->{State});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Drive '%s/%s/%s' state is '%s'", $system_name, $storage_name, $drive->{Id}, $drive->{Status}->{State})
                );
            }

            $exit = $self->get_severity(label => 'status', section => 'drive.status', value => $drive->{Status}->{Health});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Drive '%s/%s/%s' status is '%s'", $system_name, $storage_name, $drive->{Id}, $drive->{Status}->{Health})
                );
            }
        }
    }
}

1;
