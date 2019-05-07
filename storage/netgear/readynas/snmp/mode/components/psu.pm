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

package storage::netgear::readynas::snmp::mode::components::psu;

use strict;
use warnings;

my $mapping = {
    v6 => {
        psuStatus => { oid => '.1.3.6.1.4.1.4526.22.8.1.3' },
    },
    v4 => {
        psuStatus => { oid => '.1.3.6.1.4.1.4526.18.8.1.3' },
    },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{$self->{mib_ver}}->{psuStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking power supply");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping->{$self->{mib_ver}}->{psuStatus}->{oid} }})) {
        $oid =~ /^$mapping->{$self->{mib_ver}}->{psuStatus}->{oid}\.(\d+)/;
        my $instance = $1;
        my $status = $self->{results}->{ $mapping->{$self->{mib_ver}}->{psuStatus}->{oid} }->{$oid};
        
        next if ($self->check_filter(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("power supply '%s' status is %s.",
                                    $instance, $status));
        my $exit = $self->get_severity(section => 'psu', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power Supply '%s' status is %s.", $instance, $status));
        }
    }
}

1;
