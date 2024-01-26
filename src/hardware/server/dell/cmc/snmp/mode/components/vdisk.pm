#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package hardware::server::dell::cmc::snmp::mode::components::vdisk;

use strict;
use warnings;

my $map_vdisk_status = {
    1 => 'unknown', 2 => 'online',
    3 => 'failed', 4 => 'degraded'
};

my $mapping = {
    name   => { oid => '.1.3.6.1.4.1.674.10892.2.6.1.20.140.1.1.2' }, # virtualDiskName
    status => { oid => '.1.3.6.1.4.1.674.10892.2.6.1.20.140.1.1.4', map => $map_vdisk_status } # virtualDiskState
};
my $oid_vdisk_table = '.1.3.6.1.4.1.674.10892.2.6.1.20.140.1'; # virtualDiskTable

sub load {
    my ($self) = @_;

    push @{$self->{request}}, {
        oid => $oid_vdisk_table,
        start => $mapping->{name}->{oid},
        end => $mapping->{status}->{oid}
    };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking vdisks");
    $self->{components}->{vdisk} = { name => 'vdisks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'vdisk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_vdisk_table}})) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_vdisk_table}, instance => $instance);

        next if ($self->check_filter(section => 'vdisk', instance => $instance));
        $self->{components}->{vdisk}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "vdisk '%s' status is '%s' [instance: %s]",
                $result->{name},
                $result->{status},
                $instance
            )
        );

        my $exit = $self->get_severity(section => 'vdisk', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("vdisk '%s' status is '%s'", $result->{name}, $result->{status})
            );
        }
    }
}

1;
