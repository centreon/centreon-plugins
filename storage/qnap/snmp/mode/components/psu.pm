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
    ex => {
        status      => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.3.2.1.4', map => $map_status }, # systemPowerStatus
        speed       => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.3.2.1.5' }, # systemPowerFanSpeed
        temperature => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.3.2.1.6' }  # systemPowerTemp
    },
    es => {
        status      => { oid => '.1.3.6.1.4.1.24681.2.2.21.1.4' }, # es-SysPowerStatus
        speed       => { oid => '.1.3.6.1.4.1.24681.2.2.21.1.5' }, # es-SysPowerFanSpeed
        temperature => { oid => '.1.3.6.1.4.1.24681.2.2.21.1.6' }  # es-SysPowerTemp
    }
};

sub load {}

sub check_psu_result {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$options{snmp_result}})) {
        next if ($oid !~ /^$mapping->{ $options{type} }->{status}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping->{ $options{type} }, results => $options{snmp_result}, instance => $instance);

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

        if ($result->{speed} !~ /[0-9]/) {
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

sub check_psu_qts {
    my ($self, %options) = @_;

    my $oid_sysPowerStatus = '.1.3.6.1.4.1.55062.1.12.19.0';
    my $snmp_result = $self->{snmp}->get_leef(
        oids => [$oid_sysPowerStatus]
    );

    return if (!defined($snmp_result->{$oid_sysPowerStatus}));

    my $instance = 1;
    my $status = $map_status->{ $snmp_result->{$oid_sysPowerStatus} };

    return if ($self->check_filter(section => 'psu', instance => $instance));

    $self->{components}->{psu}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            "system power supply status is '%s' [instance: %s]",
            $status, $instance
        )
    );
    my $exit = $self->get_severity(section => 'psu', value => $status);
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "Sytem power supply status is '%s'", $status
            )
        );
    }
}

sub check_psu_es {
    my ($self, %options) = @_;

    my $snmp_result = $self->{snmp}->get_table(
        oid => '.1.3.6.1.4.1.24681.2.2.21', # es-SystemPowerTable
        start => $mapping->{es}->{status}->{oid}
    );
    check_psu_result($self, type => 'es', snmp_result => $snmp_result);
}

sub check_psu_ex {
    my ($self, %options) = @_;

    my $snmp_result = $self->{snmp}->get_table(
        oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.3.2', # systemPowerTable
        start => $mapping->{ex}->{status}->{oid}
    );
    check_psu_result($self, type => 'ex', snmp_result => $snmp_result);
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    if ($self->{is_qts} == 1) {
        check_psu_qts($self);
    } elsif ($self->{is_es} == 1) {
        check_psu_es($self);
    } else {
        check_psu_ex($self);
    }
}

1;
