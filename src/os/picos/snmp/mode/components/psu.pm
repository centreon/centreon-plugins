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

package os::picos::snmp::mode::components::psu;

use strict;
use warnings;

my %map_status = (
    1 => 'power-on',
    2 => 'power-off'
);

my $mapping = {
    index       => { oid => '.1.3.6.1.4.1.35098.1.11.1.1'},
    status      => { oid => '.1.3.6.1.4.1.35098.1.11.1.3', map => \%map_status }, 
    speed       => { oid => '.1.3.6.1.4.1.35098.1.11.1.5' }, 
    temperature => { oid => '.1.3.6.1.4.1.35098.1.11.1.4' }  
};

my $oid_picaRpsuEntry = '.1.3.6.1.4.1.35098.1.11.1';

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking redundancy power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    my $snmp_result = $self->{snmp}->get_table(
        oid => '.1.3.6.1.4.1.35098.1.11', 
        start => $oid_picaRpsuEntry 
    );


    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{index}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        my $celsius_fan_temp = $result->{temperature} =~ s/\s\C.*//r;

        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' status is '%s' [instance: %s, fan speed: %s, temperature: %s]",
                $instance, $result->{status}, $instance, $result->{speed}, $celsius_fan_temp
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
                        "Power supply '%s' temperature is %s C", $instance, $celsius_fan_temp
                    )
                );
            }

            $self->{output}->perfdata_add(
                nlabel => 'hardware.powersupply.temperature.celsius',
                unit => 'C',
                instances => $instance,
                value => $celsius_fan_temp
            );
        }
    }
}

1;
