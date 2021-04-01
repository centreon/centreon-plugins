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

package storage::buffalo::terastation::snmp::::mode::components::disk;

use strict;
use warnings;

my %map_disk_status = (
    1 => 'notSupport', 1 => 'normal', 2 => 'array1', 3 => 'array2',
    4 => 'standby', 5 => 'degrade', 6 => 'remove', 7 => 'standbyRemoved',
    8 => 'degradeRemoved', 9 => 'removeRemoved', 10 => 'array3',
    11 => 'array4', 12 => 'mediaCartridge', 13 => 'array5', 14 => 'array6',
);

my $mapping = {
    nasDiskStatus => { oid => '.1.3.6.1.4.1.5227.27.1.2.1.2', map => \%map_disk_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{nasDiskStatus}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = { name => 'disks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping->{nasDiskStatus}->{oid} }})) {
        $oid =~ /^$mapping->{nasDiskStatus}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{nasDiskStatus}->{oid} }, instance => $instance);

        next if ($self->check_filter(section => 'disk', instance => $instance));
        $self->{components}->{disk}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("disk '%s' status is '%s' [instance: %s].",
                                    $instance, $result->{nasDiskStatus}, $instance
                                    ));
        my $exit = $self->get_severity(section => 'disk', value => $result->{nasDiskStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Disk '%s' status is '%s'",
                                                             $instance, $result->{nasDiskStatus}));
        }
    }
}

1;
