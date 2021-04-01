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

package network::redback::snmp::mode::components::disk;

use strict;
use warnings;

my %map_disk_status = (
    1 => 'operational', 
    2 => 'degrading', 
    3 => 'failed', 
);

# In MIB 'RBN-SYS-RESOURCES-MIB'
my $mapping = {
    rbnSRStorageDescr => { oid => '.1.3.6.1.4.1.2352.2.24.1.2.1.1.2' },
    rbnSRStorageStatus => { oid => '.1.3.6.1.4.1.2352.2.24.1.2.1.1.9', map => \%map_disk_status },
};
my $oid_rbnSRStorageEntry = '.1.3.6.1.4.1.2352.2.24.1.2.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_rbnSRStorageEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rbnSRStorageEntry}})) {
        next if ($oid !~ /^$mapping->{rbnSRStorageStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_rbnSRStorageEntry}, instance => $instance);

        next if ($self->check_filter(section => 'disk', instance => $instance));
        $self->{components}->{disk}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Disk '%s' status is %s [instance: %s].",
                                    $result->{rbnSRStorageDescr}, $result->{rbnSRStorageStatus},
                                    $instance
                                    ));
        my $exit = $self->get_severity(section => 'disk', value => $result->{rbnSRStorageStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Disk '%s' status is %s",
                                                             $result->{rbnSRStorageDescr}, $result->{rbnSRStorageStatus}));
        }
    }
}

1;