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

package storage::qnap::snmp::mode::components::psu;

use strict;
use warnings;

my $map_status = {
    0 => 'ok', -1 => 'fail'
};

my $mapping = {
    status      => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.3.2.1.4', map => $map_status }, # systemPowerStatus
    speed       => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.3.2.1.5' }, # systemPowerFanSpeed
    temperature => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.3.2.1.6' }  # systemPowerTemp
};
my $oid_systemPowerTable = '.1.3.6.1.4.1.24681.1.4.1.1.1.1.3.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_systemPowerTable,
        start => $mapping->{status}->{oid},
        end => $mapping->{temperature}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_systemPowerTable}})) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_systemPowerTable}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));

        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' status is '%s' [instance: %s, fan speed: %s, temperature: %s]",
                $instance, $result->{status}, $instance, $result->{speed}, $result->{temperature}
            )
        );
        my $exit = $self->get_severity(section => 'psu', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Power supply '%s' status is '%s'", $instance, $result->{status}
                )
            );
        }

        if ($result->{speed} =~ /[0-9]/) {
            my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'psu.fanspeed', instance => $instance, value => $result->{speed});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Power supply '%s' fan speed is %s rpm", $instance, $result->{speed}
                    )
                );
            }

            $self->{output}->perfdata_add(
                nlabel => 'hardware.powersupply.fan.speed.rpm',
                unit => 'rpm',
                instances => $instance,
                value => $result->{speed},
                min => 0
            );
        }

        if ($result->{temperature} =~ /[0-9]/) {
            my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'psu.temperature', instance => $instance, value => $result->{temperature});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Power supply '%s' temperature is %s C", $instance, $result->{temperature}
                    )
                );
            }

            $self->{output}->perfdata_add(
                nlabel => 'hardware.powersupply.temperature.celsius',
                unit => 'C',
                instances => $instance,
                value => $result->{temperature}
            );
        }
    }
}

1;
