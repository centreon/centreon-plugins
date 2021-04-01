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

package storage::dell::compellent::snmp::mode::components::disk;

use strict;
use warnings;
use storage::dell::compellent::snmp::mode::components::resources qw(%map_sc_status);

my $mapping = {
    scDiskStatus        => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.14.1.3', map => \%map_sc_status },
    scDiskNamePosition  => { oid => '.1.3.6.1.4.1.674.11000.2000.500.1.2.14.1.4' },
};
my $oid_scDiskEntry = '.1.3.6.1.4.1.674.11000.2000.500.1.2.14.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_scDiskEntry, begin => $mapping->{scDiskStatus}->{oid}, end => $mapping->{scDiskNamePosition}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_scDiskEntry}})) {
        next if ($oid !~ /^$mapping->{scDiskStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_scDiskEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'disk', instance => $instance));
        $self->{components}->{disk}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("disk '%s' status is '%s' [instance = %s]",
                                    $result->{scDiskNamePosition}, $result->{scDiskStatus}, $instance, 
                                    ));
        
        my $exit = $self->get_severity(label => 'default', section => 'disk', value => $result->{scDiskStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' status is '%s'", $result->{scDiskNamePosition}, $result->{scDiskStatus}));
        }
    }
}

1;