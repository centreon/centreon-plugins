#
# Copyright 2018 Centreon (http://www.centreon.com/)
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
# Author : ArnoMLT
#

package storage::netgear::readynas::snmp::mode::components::fan;

use strict;
use warnings;

my $mapping = {
    v6 => {
        fanStatus   => { oid => '.1.3.6.1.4.1.4526.22.4.1.3' },
    },
    v4 => {
        fanRPM      => { oid => '.1.3.6.1.4.1.4526.18.4.1.2' },
    },
};

sub load {
    my ($self) = @_;

    if ($self->{mib_ver} eq 'v4') {
        push @{$self->{request}}, { oid => $mapping->{$self->{mib_ver}}->{fanRPM}->{oid} };
    } else {
        push @{$self->{request}}, { oid => $mapping->{$self->{mib_ver}}->{fanStatus}->{oid} };
    }
}

sub check_v6 {
    my ($self) = @_;
    
    return if ($self->{mib_ver} ne 'v6');
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping->{$self->{mib_ver}}->{fanStatus}->{oid} }})) {
        $oid =~ /^$mapping->{$self->{mib_ver}}->{fanStatus}->{oid}\.(\d+)/;
        my $instance = $1;
        my $status = $self->{results}->{ $mapping->{$self->{mib_ver}}->{fanStatus}->{oid} }->{$oid};

        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is %s.", $instance, $status));
        my $exit = $self->get_severity(label => 'default', section => 'fan', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("fan '%s' status is %s", $instance, $status));
        }
    }
}

sub check_v4 {
    my ($self) = @_;
    
    return if ($self->{mib_ver} ne 'v4');
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping->{$self->{mib_ver}}->{fanRPM}->{oid} }})) {
        $oid =~ /^$mapping->{$self->{mib_ver}}->{fanRPM}->{oid}\.(\d+)/;
        my $instance = $1;
        my $fanrpm = $self->{results}->{ $mapping->{$self->{mib_ver}}->{fanRPM}->{oid} }->{$oid};

        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("fan '%s' rpm is %s.", $instance, $fanrpm));    
        my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $fanrpm);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("fan '%s' rpm is %s", $instance, $fanrpm));
        }
        
        $self->{output}->perfdata_add(
            label => "fan", unit => 'rpm',
            nlabel => 'hardware.fan.speed.rpm',
            instances => $instance,
            value => $fanrpm,
            warning => $warn,
            critical => $crit
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking fan");
    $self->{components}->{fan} = {name => 'fan', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    check_v6($self);
    check_v4($self);    
}

1;
