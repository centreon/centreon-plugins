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

package centreon::common::redfish::restapi::mode::components::fan;

use strict;
use warnings;

my $reading_units = {
    percent => { short => '%', long => 'percentage' },
    rpm => { short => 'rpm', long => 'rpm' }
};

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking fans');
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    $self->get_chassis() if (!defined($self->{chassis}));

    foreach my $chassis (@{$self->{chassis}}) {
        my $chassis_name = 'chassis:' . $chassis->{Id};

        $chassis->{Thermal}->{result} = $self->get_thermal(chassis => $chassis) if (!defined($chassis->{Thermal}->{result}));
        next if (!defined($chassis->{Thermal}->{result}->{Fans}));

        foreach my $fan (@{$chassis->{Thermal}->{result}->{Fans}}) {
            my $fan_name = $fan->{Name};
            my $instance = $chassis->{Id} . '.' . $fan->{MemberId};

            $fan->{Status}->{Health} = defined($fan->{Status}->{Health}) ? $fan->{Status}->{Health} : 'n/a';
            next if ($self->check_filter(section => 'fan', instance => $instance));
            $self->{components}->{fan}->{total}++;
            
            $self->{output}->output_add(
                long_msg => sprintf(
                    "fan '%s/%s' status is '%s' [instance: %s, state: %s, speed: %s %s]",
                    $chassis_name, $fan_name, $fan->{Status}->{Health}, $instance, $fan->{Status}->{State},
                    $fan->{Reading}, $fan->{ReadingUnits}
                )
            );

            my $exit = $self->get_severity(label => 'state', section => 'fan.state', value => $fan->{Status}->{State});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Fan '%s/%s' state is '%s'", $chassis_name, $fan_name, $fan->{Status}->{State})
                );
            }

            $exit = $self->get_severity(label => 'status', section => 'fan.status', value => $fan->{Status}->{Health});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Fan '%s/%s' status is '%s'", $chassis_name, $fan_name, $fan->{Status}->{Health})
                );
            }

            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $fan->{Reading});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf(
                        "Fan '%s/%s' speed is %s %s",
                        $chassis_name, $fan_name, $fan->{Reading}, $reading_units->{lc($fan->{ReadingUnits})}->{short}
                    )
                );
            }
            $self->{output}->perfdata_add(
                unit => $reading_units->{lc($fan->{ReadingUnits})}->{short},
                nlabel => 'hardware.fan.speed.' . $reading_units->{lc($fan->{ReadingUnits})}->{long},
                instances => [$chassis_name, $fan_name],
                value => $fan->{Reading},
                warning => $warn,
                critical => $crit,
                min => 0,
                max => $fan->{ReadingUnits} eq 'Percent' ? 100 : undef
            );
        }
    }
}

1;
