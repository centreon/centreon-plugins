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

package storage::netgear::readynas::snmp::mode::components::disk;

use strict;
use warnings;

my $mapping = {
    v6 => {
        diskState       => { oid => '.1.3.6.1.4.1.4526.22.3.1.9' },
        diskTemperature => { oid => '.1.3.6.1.4.1.4526.22.3.1.10' },
    },
    v4 => {
        diskState       => { oid => '.1.3.6.1.4.1.4526.18.3.1.4' },
        diskTemperature => { oid => '.1.3.6.1.4.1.4526.18.3.1.5' },
    },
};
my $oid_diskTable = {
    v4 => '.1.3.6.1.4.1.4526.18.3',
    v6 => '.1.3.6.1.4.1.4526.22.3',
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_diskTable->{$self->{mib_ver}}, 
        start => $mapping->{$self->{mib_ver}}->{diskState}, end => $mapping->{$self->{mib_ver}}->{diskTemperature} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking disks");
    $self->{components}->{disk} = {name => 'disk', total => 0, skip => 0};
    return if ($self->check_filter(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $oid_diskTable->{$self->{mib_ver}} }})) {
        next if ($oid !~ /^$mapping->{$self->{mib_ver}}->{diskState}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping->{$self->{mib_ver}}, results => $self->{results}->{ $oid_diskTable->{$self->{mib_ver}} }, instance => $instance);

        next if ($self->check_filter(section => 'disk', instance => $instance));
        $self->{components}->{disk}->{total}++;

        my $temperature_string = defined($result->{diskTemperature}) && $result->{diskTemperature} != -1 ? " (temperature $result->{diskTemperature}" : '';
        my $temperature_unit = $temperature_string ne '' && $self->{mib_ver} == 6 ? 'C)' : '';
        $temperature_unit = $temperature_string ne '' && $self->{mib_ver} == 4 ? 'F)' : '';
        
        $self->{output}->output_add(long_msg => sprintf("disk '%s' status is %s [temperature: %s%s]",
                                    $instance, $result->{diskState}, $temperature_string, $temperature_unit));

        my $exit = $self->get_severity(section => 'disk', value => $result->{diskState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' status is %s", $instance, $result->{diskState}));
        }
    }
}

1;
