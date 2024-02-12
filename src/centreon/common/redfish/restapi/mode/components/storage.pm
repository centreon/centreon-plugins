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

package centreon::common::redfish::restapi::mode::components::storage;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking storages');
    $self->{components}->{storage} = { name => 'storages', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'storage'));

    $self->get_storages() if (!defined($self->{storages}));

    foreach my $storage (@{$self->{storages}}) {
        $storage->{'@odata.id'} =~ /Systems\/(\d+)\//;
        my $system_id = $1;
        my $system_name = 'system:' . $1;

        my $storage_name = $storage->{Id};
        my $instance = $system_id . '.' . $storage->{Id};

        $storage->{Status}->{Health} = defined($storage->{Status}->{HealthRollup}) ? $storage->{Status}->{HealthRollup} : 'n/a';
        $storage->{Status}->{State} = defined($storage->{Status}->{State}) ? $storage->{Status}->{State} : 'n/a';
        next if ($self->check_filter(section => 'storage', instance => $instance));
        $self->{components}->{storage}->{total}++;
        
        $self->{output}->output_add(
            long_msg => sprintf(
                "storage '%s/%s' status is '%s' [instance: %s, state: %s]",
                $system_name, $storage_name, $storage->{Status}->{Health}, $instance, $storage->{Status}->{State}
            )
        );

        my $exit = $self->get_severity(label => 'state', section => 'storage.state', value => $storage->{Status}->{State});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Storage '%s/%s' state is '%s'", $system_name, $storage_name, $storage->{Status}->{State})
            );
        }

        $exit = $self->get_severity(label => 'status', section => 'storage.status', value => $storage->{Status}->{Health});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Storage '%s/%s' status is '%s'", $system_name, $storage_name, $storage->{Status}->{Health})
            );
        }
    }
}

1;
