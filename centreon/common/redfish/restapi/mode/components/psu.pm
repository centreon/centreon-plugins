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

package centreon::common::redfish::restapi::mode::components::psu;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking power supplies');
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    $self->get_chassis() if (!defined($self->{chassis}));

    foreach my $chassis (@{$self->{chassis}}) {
        my $chassis_name = 'chassis:' . $chassis->{Id};

        $chassis->{Power}->{result} = $self->get_power(chassis => $chassis) if (!defined($chassis->{Power}->{result}));
        next if (!defined($chassis->{Power}->{result}->{PowerSupplies}));

        foreach my $psu (@{$chassis->{Power}->{result}->{PowerSupplies}}) {
            my $psu_name = 'psu:' . $psu->{MemberId};
            my $instance = $chassis->{Id} . '.' . $psu->{MemberId};

            $psu->{Status}->{Health} = defined($psu->{Status}->{Health}) ? $psu->{Status}->{Health} : 'n/a';
            next if ($self->check_filter(section => 'psu', instance => $instance));
            $self->{components}->{psu}->{total}++;
            
            $self->{output}->output_add(
                long_msg => sprintf(
                    "power supply '%s/%s' status is '%s' [instance: %s, state: %s, value: %s]",
                    $chassis_name, $psu_name, $psu->{Status}->{Health}, $instance, $psu->{Status}->{State},
                    $psu->{LastPowerOutputWatts},
                )
            );

            my $exit = $self->get_severity(label => 'state', section => 'psu.state', value => $psu->{Status}->{State});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Power supply '%s/%s' state is '%s'", $chassis_name, $psu_name, $psu->{Status}->{State})
                );
            }

            $exit = $self->get_severity(label => 'status', section => 'psu.status', value => $psu->{Status}->{Health});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf("Power supply '%s/%s' status is '%s'", $chassis_name, $psu_name, $psu->{Status}->{Health})
                );
            }

            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu', instance => $instance, value => $psu->{LastPowerOutputWatts});

            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf(
                        "Power supply '%s/%s' power is %s W",
                        $chassis_name, $psu_name, $psu->{LastPowerOutputWatts}
                    )
                );
            }
            $self->{output}->perfdata_add(
                unit => 'W',
                nlabel => 'hardware.powersupply.power.watt',
                instances => [$chassis_name, $psu_name],
                value => $psu->{LastPowerOutputWatts},
                warning => $warn,
                critical => $crit,
                min => 0
            );
        }
    }
}

1;
