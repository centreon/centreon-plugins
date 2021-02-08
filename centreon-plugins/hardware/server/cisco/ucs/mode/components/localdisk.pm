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

package hardware::server::cisco::ucs::mode::components::localdisk;

use strict;
use warnings;
use hardware::server::cisco::ucs::mode::components::resources qw(%mapping_presence %mapping_operability);

# In MIB 'CISCO-UNIFIED-COMPUTING-STORAGE-MIB'
my $mapping1 = {
    cucsStorageLocalDiskPresence => { oid => '.1.3.6.1.4.1.9.9.719.1.45.4.1.10', map => \%mapping_presence },
};
my $mapping2 = {
    cucsStorageLocalDiskOperability => { oid => '.1.3.6.1.4.1.9.9.719.1.45.4.1.9', map => \%mapping_operability },
};
my $oid_cucsStorageLocalDiskDn = '.1.3.6.1.4.1.9.9.719.1.45.4.1.2';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $mapping1->{cucsStorageLocalDiskPresence}->{oid} },
        { oid => $mapping2->{cucsStorageLocalDiskOperability}->{oid} }, { oid => $oid_cucsStorageLocalDiskDn };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking local disks");
    $self->{components}->{localdisk} = {name => 'local disks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'localdisk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cucsStorageLocalDiskDn}})) {
        $oid =~ /\.(\d+)$/;
        my $instance = $1;
        my $localdisk_dn = $self->{results}->{$oid_cucsStorageLocalDiskDn}->{$oid};
        my $result = $self->{snmp}->map_instance(mapping => $mapping1, results => $self->{results}->{$mapping1->{cucsStorageLocalDiskPresence}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{cucsStorageLocalDiskOperability}->{oid}}, instance => $instance);

        next if ($self->absent_problem(section => 'localdisk', instance => $localdisk_dn));
        next if ($self->check_filter(section => 'localdisk', instance => $localdisk_dn));

        $self->{output}->output_add(
            long_msg => sprintf(
                "local disk '%s' state is '%s' [presence: %s].",
                $localdisk_dn, $result2->{cucsStorageLocalDiskOperability},
                $result->{cucsStorageLocalDiskPresence}
            )
        );

        my $exit = $self->get_severity(section => 'localdisk.presence', label => 'default.presence', value => $result->{cucsStorageLocalDiskPresence});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "local disk '%s' presence is: '%s'",
                    $localdisk_dn, $result->{cucsStorageLocalDiskPresence})
            );
            next;
        }

        $self->{components}->{localdisk}->{total}++;

        $exit = $self->get_severity(section => 'localdisk.operability', label => 'default.operability', value => $result2->{cucsStorageLocalDiskOperability});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "local disk '%s' state is '%s'",
                    $localdisk_dn, $result2->{cucsStorageLocalDiskOperability}
                )
            );
        }
    }
}

1;
