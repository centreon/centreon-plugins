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

package centreon::common::redfish::restapi::mode::components::volume;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking volumes');
    $self->{components}->{volume} = { name => 'volumes', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'volume'));

    $self->get_storages() if (!defined($self->{storages}));

    foreach my $storage (@{$self->{storages}}) {
        $storage->{'@odata.id'} =~ /Systems\/(\d+)\//;
        my $system_id = $1;
        my $system_name = 'system:' . $1;

        my $storage_name = $storage->{Id};

        my $volumes = $self->get_volumes(storage => $storage);

        foreach my $volume (@$volumes) {
            my $instance = $system_id . '.' . $storage->{Id} . '.' . $volume->{Id};

            $volume->{Status}->{Health} = defined($volume->{Status}->{Health}) ? $volume->{Status}->{Health} : 'n/a';
            $volume->{Status}->{State} = defined($volume->{Status}->{State}) ? $volume->{Status}->{State} : 'n/a';
            next if ($self->check_filter(section => 'volume', instance => $instance));
            $self->{components}->{volume}->{total}++;
            
            $self->{output}->output_add(
                long_msg => sprintf(
                    "volume '%s/%s/%s' status is '%s' [instance: %s, state: %s]",
                    $system_name, $storage_name, $volume->{Id}, $volume->{Status}->{Health}, $instance, $volume->{Status}->{State}
                )
            );

            my $exit = $self->get_severity(label => 'state', section => 'volume.state', value => $volume->{Status}->{State});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Volume '%s/%s/%s' state is '%s'", $system_name, $storage_name, $volume->{Id}, $volume->{Status}->{State})
                );
            }

            $exit = $self->get_severity(label => 'status', section => 'volume.status', value => $volume->{Status}->{Health});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Volume '%s/%s/%s' status is '%s'", $system_name, $storage_name, $volume->{Id}, $volume->{Status}->{Health})
                );
            }
        }
    }
}

1;
