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

package storage::netapp::santricity::restapi::mode::components::thsensor;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking thermal sensors');
    $self->{components}->{thsensor} = { name => 'thsensor', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'thsensor'));

    return if (!defined($self->{json_results}->{storages}));

    foreach (@{$self->{json_results}->{storages}}) {
        my $storage_name = $_->{name};

        next if ($self->check_filter(section => 'storage', instance => $_->{chassisSerialNumber}));
        
        next if (!defined($_->{'/hardware-inventory'}->{thermalSensors}));

        foreach my $entry (@{$_->{'/hardware-inventory'}->{thermalSensors}}) {
            my $instance = $entry->{thermalSensorRef};
            my $name = $storage_name . ($entry->{physicalLocation}->{label} ne '' ? ':' . $entry->{physicalLocation}->{label} : '') . ':' . $entry->{physicalLocation}->{locationPosition} . ':' . $entry->{physicalLocation}->{slot};

            next if ($self->check_filter(section => 'thsensor', instance => $instance));
            $self->{components}->{thsensor}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "thermal sensor '%s' status is '%s' [instance = %s]",
                    $name, $entry->{status}, $instance,
                )
            );

            my $exit = $self->get_severity(section => 'thsensor', instance => $instance, value => $entry->{status});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Thermal sensor '%s' status is '%s'", $name, $entry->{status})
                );
            }
        }
    }
}

1;
