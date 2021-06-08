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

package storage::qnap::snmp::mode::components::fan;

use strict;
use warnings;

my $map_status = {
    0 => 'ok', -1 => 'fail'
};

my $mapping = {
    legacy => {
        description => { oid => '.1.3.6.1.4.1.24681.1.2.15.1.2' }, # sysFanDescr
        speed       => { oid => '.1.3.6.1.4.1.24681.1.2.15.1.3' }  # sysFanSpeed
    },
    ex => {
        description => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.2.2.1.2' }, # systemFanID
        status      => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.2.2.1.4', map => $map_status }, # systemFanStatus
        speed       => { oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.2.2.1.5' }, # systemFanSpeed
    },
    es => {
        description => { oid => '.1.3.6.1.4.1.24681.2.2.15.1.2' }, # es-SysFanDescr
        speed       => { oid => '.1.3.6.1.4.1.24681.2.2.15.1.3' }  # es-SysFanSpeed
    }
};

sub load {}

sub check_fan_result {
    my ($self, %options) = @_;
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$options{snmp_result}})) {
        next if ($oid !~ /^$mapping->{ $options{type} }->{description}->{oid}\.(.*)$/);
        my $instance = $1;
        $self->{fan_checked} = 1;

        my $result = $self->{snmp}->map_instance(mapping => $mapping->{ $options{type} }, results => $options{snmp_result}, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance));        
        $self->{components}->{fan}->{total}++;

        $result->{speed} = defined($result->{speed}) ? $result->{speed} : 'unknown';
        $result->{status} = defined($result->{status}) ? $result->{status} : 'n/a';
        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' speed is %s [instance: %s, status: %s]",
                $result->{description}, $result->{speed}, $instance, 
                $result->{status}
            )
        );

        if ($result->{speed} =~ /([0-9]+)\s*rpm/i) {
            my $fan_speed_value = $1;
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $fan_speed_value);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Fan '%s' speed is %s rpm", $result->{description}, $fan_speed_value
                    )
                );
            }
            $self->{output}->perfdata_add(
                nlabel => 'hardware.fan.speed.rpm',
                unit => 'rpm',
                instances => $instance,
                value => $fan_speed_value,
                min => 0
            );
        }
    }
}

sub check_fan_es {
    my ($self, %options) = @_;

    my $snmp_result = $self->{snmp}->get_table(
        oid => '.1.3.6.1.4.1.24681.2.2.15', # es-SystemFanTable
        start => $mapping->{es}->{description}->{oid}
    );
    check_fan_result($self, type => 'es', snmp_result => $snmp_result);
}

sub check_fan_legacy {
    my ($self, %options) = @_;

    return if (defined($self->{fan_checked}));

    my $snmp_result = $self->{snmp}->get_table(
        oid => '.1.3.6.1.4.1.24681.1.2.15', # systemFanTable
        start => $mapping->{legacy}->{description}->{oid}
    );
    check_fan_result($self, type => 'legacy', snmp_result => $snmp_result);
}

sub check_fan_ex {
    my ($self, %options) = @_;

    my $snmp_result = $self->{snmp}->get_table(
        oid => '.1.3.6.1.4.1.24681.1.4.1.1.1.1.2.2', # systemFan2Table
        start => $mapping->{ex}->{description}->{oid}
    );
    check_fan_result($self, type => 'ex', snmp_result => $snmp_result);
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    if ($self->{is_es} == 1) {
        check_fan_es($self);
    } else {
        check_fan_ex($self);
        check_fan_legacy($self);
    }
}

1;
