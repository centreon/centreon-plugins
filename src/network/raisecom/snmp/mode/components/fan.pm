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

package network::raisecom::snmp::mode::components::fan;

use strict;
use warnings;

my %map_fan_state = (
    1 => 'normal',
    2 => 'abnormal',
);

my %map_pon_fan_state = (
    1 => 'normal',
    2 => 'abnormal',
    3 => 'null',
    4 => 'unknown',
);

my $mapping = {
    raisecomFanSpeedValue   => { oid => '.1.3.6.1.4.1.8886.1.1.5.2.2.1.2' },
    raisecomFanWorkState    => { oid => '.1.3.6.1.4.1.8886.1.1.5.2.2.1.3', map => \%map_fan_state },
};

my $mapping_pon = {
    raisecomFanSpeedValue   => { oid => '.1.3.6.1.4.1.8886.1.27.5.1.1.4' },
    raisecomFanWorkState    => { oid => '.1.3.6.1.4.1.8886.1.27.5.1.1.3', map => \%map_pon_fan_state },
};


my $oid_raisecomFanMonitorStateEntry = '.1.3.6.1.4.1.8886.1.1.5.2.2.1';
my $oid_pon_raisecomFanMonitorStateEntry = '.1.3.6.1.4.1.8886.1.27.5.1.1';

sub load {
}

sub check_fan {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$options{entry}})) {
        next if ($oid !~ /^$mapping->{raisecomFanWorkState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $options{entry}, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance));

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "Fan '%s' status is '%s' [instance: %s][speed: %s]",
                $instance, 
                $result->{raisecomFanWorkState}, 
                $instance,
                $result->{raisecomFanSpeedValue}
            )
        );

        my $exit = $self->get_severity(section => 'fan', value => $result->{raisecomFanWorkState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Fan '%s' status is '%s'", 
                    $instance, 
                    $result->{raisecomFanWorkState}
                )
            );
        }

        my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'fan.speed', instance => $instance, value => $result->{raisecomFanSpeedValue});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf("Fan speed '%s' is %s rpm", $instance, $result->{raisecomFanSpeedValue})
            );
        }

        $self->{output}->perfdata_add(
            unit => 'rpm',
            nlabel => 'hardware.fan.speed.rpm',
            instances => $instance,
            value => $result->{raisecomFanSpeedValue},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }

}

sub check_pon_fan {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$options{entry}})) {
        next if ($oid !~ /^$mapping_pon->{raisecomFanWorkState}->{oid}\.(.*)$/);
        my $fan = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_pon, results => $options{entry}, instance => $fan);

        next if ($self->check_filter(section => 'fan', instance => $fan));

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "Fan '%s' status is '%s' [instance: %s][speed: %s]",
                $fan, 
                $result->{raisecomFanWorkState}, 
                $fan,
                $result->{raisecomFanSpeedValue}
            )
        );
        my $exit = $self->get_severity(section => 'fan', value => $result->{raisecomFanWorkState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Fan '%s' status is '%s'", 
                    $fan, 
                    $result->{raisecomFanWorkState}
                )
            );
        }

        my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'fan.speed', instance => $fan, value => $result->{raisecomFanSpeedValue});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Fan speed '%s' is %s rpm", 
                    $fan,
                    $result->{raisecomFanSpeedValue}
                )
            );
        }

        $self->{output}->perfdata_add(
            unit => 'rpm',
            nlabel => 'hardware.fan.speed.rpm',
            instances => $fan,
            value => $result->{raisecomFanSpeedValue},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fan', total => 0, skip => 0};

    return if ($self->check_filter(section => 'fan'));

    my $snmp_result = $self->{snmp}->get_table(oid => $oid_raisecomFanMonitorStateEntry);
    if (scalar(keys %{$snmp_result}) <= 0) {
        my $snmp_result_pon = $self->{snmp}->get_table(oid => $oid_pon_raisecomFanMonitorStateEntry);

        check_pon_fan($self, entry => $snmp_result_pon)
    } else {
        check_fan($self, entry => $snmp_result);
    }
}

1;
