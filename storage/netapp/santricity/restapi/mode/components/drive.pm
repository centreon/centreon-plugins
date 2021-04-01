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

package storage::netapp::santricity::restapi::mode::components::drive;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking drives');
    $self->{components}->{drive} = { name => 'drive', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'drive'));

    return if (!defined($self->{json_results}->{storages}));

    foreach (@{$self->{json_results}->{storages}}) {
        my $storage_name = $_->{name};

        next if ($self->check_filter(section => 'storage', instance => $_->{chassisSerialNumber}));
        
        next if (!defined($_->{'/hardware-inventory'}->{drives}));

        foreach my $entry (@{$_->{'/hardware-inventory'}->{drives}}) {
            my $instance = $entry->{driveRef};
            my $name = $storage_name . ':' . $entry->{physicalLocation}->{locationPosition} . ':' . $entry->{physicalLocation}->{slot};

            next if ($self->check_filter(section => 'drive', instance => $instance));
            $self->{components}->{drive}->{total}++;

            $self->{output}->output_add(
                long_msg => sprintf(
                    "drive '%s' status is '%s' [instance = %s] [temperature: %s]",
                    $name, $entry->{status}, $instance, $entry->{driveTemperature}->{currentTemp}
                )
            );

            my $exit = $self->get_severity(section => 'drive', instance => $instance, value => $entry->{status});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Drive '%s' status is '%s'", $name, $entry->{status})
                );
            }

            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'drive.temperature', instance => $instance, value => $entry->{driveTemperature}->{currentTemp});
            if ($checked == 0) {
                my $warn_th = '';
                my $crit_th = defined($entry->{driveTemperature}->{refTemp}) ? $entry->{driveTemperature}->{refTemp} : '';
                $self->{perfdata}->threshold_validate(label => 'warning-drive.temperature-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-drive.temperature-instance-' . $instance, value => $crit_th);

                $exit = $self->{perfdata}->threshold_check(
                    value => $entry->{driveTemperature}->{currentTemp},
                    threshold => [
                        { label => 'critical-drive.temperature-instance-' . $instance, exit_litteral => 'critical' },
                        { label => 'warning-drive.temperature-instance-' . $instance, exit_litteral => 'warning' }
                    ]
                );
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-drive.temperature-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-drive.temperature-instance-' . $instance)
            }

            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf("drive '%s' temperature is %s C", $name, $entry->{driveTemperature}->{currentTemp})
                );
            }

            $self->{output}->perfdata_add(
                nlabel => 'hardware.drive.temperature.celsius',
                unit => 'C',
                instances => $name,
                value => $entry->{driveTemperature}->{currentTemp},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
