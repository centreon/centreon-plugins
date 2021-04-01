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

package centreon::common::redfish::restapi::mode::components::temperature;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking temperatures');
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    $self->get_chassis() if (!defined($self->{chassis}));

    foreach my $chassis (@{$self->{chassis}}) {
        my $chassis_name = 'chassis:' . $chassis->{Id};

        $chassis->{Thermal}->{result} = $self->get_thermal(chassis => $chassis) if (!defined($chassis->{Thermal}->{result}));
        next if (!defined($chassis->{Thermal}->{result}->{Temperatures}));

        foreach my $temp (@{$chassis->{Thermal}->{result}->{Temperatures}}) {
            my $temp_name = $temp->{Name};
            my $instance = $chassis->{Id} . '.' . $temp->{MemberId};

            $temp->{Status}->{Health} = defined($temp->{Status}->{Health}) ? $temp->{Status}->{Health} : 'n/a';
            next if ($self->check_filter(section => 'temperature', instance => $instance));
            $self->{components}->{temperature}->{total}++;
            
            $self->{output}->output_add(
                long_msg => sprintf(
                    "temperature '%s/%s' status is '%s' [instance: %s, state: %s, value: %s]",
                    $chassis_name, $temp_name, $temp->{Status}->{Health}, $instance, $temp->{Status}->{State},
                    $temp->{ReadingCelsius}
                )
            );

            my $exit = $self->get_severity(label => 'state', section => 'temperature.state', value => $temp->{Status}->{State});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Temperature '%s/%s' state is '%s'", $chassis_name, $temp_name, $temp->{Status}->{State})
                );
            }

            $exit = $self->get_severity(label => 'status', section => 'temperature.status', value => $temp->{Status}->{Health});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Temperature '%s/%s' status is '%s'", $chassis_name, $temp_name, $temp->{Status}->{Health})
                );
            }

            next if (!defined($temp->{ReadingCelsius}) || $temp->{ReadingCelsius} == 0);

            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $temp->{ReadingCelsius});
            if ($checked == 0) {
                my $warn_th = defined($temp->{UpperThresholdCritical}) ? ':' . $temp->{UpperThresholdCritical} : '';
                my $crit_th = defined($temp->{UpperThresholdFatal}) ? ':' . $temp->{UpperThresholdFatal} : '';
                $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
            }
            
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf(
                        "Temperature '%s/%s' is %s C",
                        $chassis_name, $temp_name, $temp->{ReadingCelsius}
                    )
                );
            }
            $self->{output}->perfdata_add(
                unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => [$chassis_name, $temp_name],
                value => $temp->{ReadingCelsius},
                warning => $warn,
                critical => $crit,
            );
        }
    }
}

1;
