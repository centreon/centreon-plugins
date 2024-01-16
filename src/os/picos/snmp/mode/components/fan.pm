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

package os::picos::snmp::mode::components::fan;

use strict;
use warnings;

my $oid_picaFanSpeed = '.1.3.6.1.4.1.35098.1.8.0'; # fanSpeed

sub load {
    my ($self) = @_;
    
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking fan');
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    my ($exit, $warn, $crit, $checked);
    my $instance = 0; # we only have 1 fan

    my $result = $self->{snmp}->get_leef(oids => [$oid_picaFanSpeed ], nothing_quit => 1);

    my $fan_speed = $result->{$oid_picaFanSpeed} =~ s/RPM//r;

    next if ($self->check_filter(section => 'fan', instance => $instance));

    $self->{components}->{fan}->{total} = 1;
    $self->{output}->output_add(
        long_msg => sprintf(
            "fan '%s' [instance: %s, rpm: %s]",
            $instance, $instance, $fan_speed
        )
    );

    ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $fan_speed);            
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "fan '%s' speed is '%s' rpm", $instance, $fan_speed
            )
        );
    }
    $self->{output}->perfdata_add(
        nlabel => 'hardware.fan.speed.rpm',
        unit => 'rpm',
        instances => $instance,
        value => $fan_speed,
        warning => $warn,
        critical => $crit, min => 0
    );
}

1;
