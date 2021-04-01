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

package storage::dell::equallogic::snmp::mode::components::disk;

use strict;
use warnings;

my %map_disk_status = (
    1 => 'on-line',
    2 => 'spare',
    3 => 'failed',
    4 => 'off-line',
    5 => 'alt-sig',
    6 => 'too-small',
    7 => 'history-of-failures',
    8 => 'unsupported-version',
    9 => 'unhealthy',
    10 => 'replacement',
);

# In MIB 'eqldisk.mib'
my $mapping = {
    eqlDiskStatus => { oid => '.1.3.6.1.4.1.12740.3.1.1.1.8', map => \%map_disk_status },
};
my $oid_eqlDiskStatus = '.1.3.6.1.4.1.12740.3.1.1.1.8';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_eqlDiskStatus };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_eqlDiskStatus}})) {
        next if ($oid !~ /^$mapping->{eqlDiskStatus}->{oid}\.(\d+\.\d+)\.(.*)$/);
        my ($member_instance, $instance) = ($1, $2);
        my $member_name = $self->get_member_name(instance => $member_instance);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_eqlDiskStatus}, instance => $member_instance . '.' . $instance);

        next if ($self->check_filter(section => 'disk', instance => $member_instance . '.' . $instance));
        $self->{components}->{disk}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Disk '%s/%s' status is %s [instance: %s].",
                                    $member_name, $instance, $result->{eqlDiskStatus}, $member_instance . '.' . $instance
                                    ));
        my $exit = $self->get_severity(section => 'disk', value => $result->{eqlDiskStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Disk '%s/%s' status is %s",
                                                             $member_name, $instance, $result->{eqlDiskStatus}));
        }
    }
}

1;