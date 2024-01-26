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

package centreon::common::redfish::restapi::mode::components::sc;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking storage controllers');
    $self->{components}->{sc} = { name => 'sc', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'sc'));

    $self->get_storages() if (!defined($self->{storages}));

    foreach my $storage (@{$self->{storages}}) {
        $storage->{'@odata.id'} =~ /Systems\/(\d+)\//;
        my $system_id = $1;
        my $system_name = 'system:' . $1;

        my $storage_name = $storage->{Id};

        foreach my $sc (@{$storage->{StorageControllers}}) {
            my $instance .= $system_id . '.' . $storage->{Id} . '.' . $sc->{MemberId};

            my $sc_name = $sc->{MemberId};

            $sc->{Status}->{Health} = defined($sc->{Status}->{Health}) ? $sc->{Status}->{Health} : 'n/a';
            $sc->{Status}->{State} = defined($sc->{Status}->{State}) ? $sc->{Status}->{State} : 'n/a';
            next if ($self->check_filter(section => 'sc', instance => $instance));
            $self->{components}->{sc}->{total}++;
            
            $self->{output}->output_add(
                long_msg => sprintf(
                    "storage controller '%s/%s/%s' status is '%s' [instance: %s, state: %s]",
                    $system_name, $storage_name, $sc_name, $sc->{Status}->{Health}, $instance, $sc->{Status}->{State}
                )
            );

            my $exit = $self->get_severity(label => 'state', section => 'sc.state', value => $sc->{Status}->{State});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Storage controller '%s/%s/%s' state is '%s'", $system_name, $storage_name, $sc_name, $sc->{Status}->{State})
                );
            }

            $exit = $self->get_severity(label => 'status', section => 'sc.status', value => $sc->{Status}->{Health});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Storage controller '%s/%s/%s' status is '%s'", $system_name, $storage_name, $sc_name, $sc->{Status}->{Health})
                );
            }
        }
    }
}

1;
