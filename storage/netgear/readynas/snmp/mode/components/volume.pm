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

package storage::netgear::readynas::snmp::mode::components::volume;

use strict;
use warnings;

my $mapping = {
    v6 => {
        volumeName    => { oid => '.1.3.6.1.4.1.4526.22.7.1.2' },
        volumeStatus  => { oid => '.1.3.6.1.4.1.4526.22.7.1.4' },
    },
    v4 => {
        volumeName    => { oid => '.1.3.6.1.4.1.4526.18.7.1.2' },
        volumeStatus  => { oid => '.1.3.6.1.4.1.4526.18.7.1.4' },
    },
};
my $oid_volumeTable = {
    v4 => '.1.3.6.1.4.1.4526.18.7',
    v6 => '.1.3.6.1.4.1.4526.22.7',
};

sub load {
    my ($self) = @_;
    
     push @{$self->{request}}, { oid => $oid_volumeTable->{$self->{mib_ver}}, 
        start => $mapping->{$self->{mib_ver}}->{volumeName}, end => $mapping->{$self->{mib_ver}}->{volumeStatus} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking volume");
    $self->{components}->{volume} = {name => 'volume', total => 0, skip => 0};
    return if ($self->check_filter(section => 'volume'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $oid_volumeTable->{$self->{mib_ver}} }})) {
        next if ($oid !~ /^$mapping->{$self->{mib_ver}}->{volumeStatus}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping->{$self->{mib_ver}}, results => $self->{results}->{ $oid_volumeTable->{$self->{mib_ver}} }, instance => $instance);

        next if ($self->check_filter(section => 'volume', instance => $instance));
        $self->{components}->{volume}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("volume '%s' status is %s [instance: %s]",
                                    $result->{volumeName}, $result->{volumeStatus}, $instance));
        my $exit = $self->get_severity(section => 'volume', value => $result->{volumeStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Volume '%s' status is %s", 
                                                             $result->{volumeName}, $result->{volumeStatus}));
        }
    }
}

1;
