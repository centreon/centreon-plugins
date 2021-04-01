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

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::disk;

use strict;
use warnings;
use centreon::plugins::misc;

my $mapping = {
    diskDescr        => { oid => '.1.3.6.1.4.1.2.3.51.3.1.12.2.1.2' },
    diskHealthStatus => { oid => '.1.3.6.1.4.1.2.3.51.3.1.12.2.1.3' }
};
my $oid_diskEntry = '.1.3.6.1.4.1.2.3.51.3.1.12.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_diskEntry, start => $mapping->{diskDescr}->{oid}, end => $mapping->{diskHealthStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = { name => 'disks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_diskEntry}})) {
        next if ($oid !~ /^$mapping->{diskDescr}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_diskEntry}, instance => $instance);

        next if ($self->check_filter(section => 'disk', instance => $instance));

        $self->{components}->{disk}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "disk '%s' is '%s' [instance = %s]",
                $result->{diskDescr},
                $result->{diskHealthStatus},
                $instance
            )
        );
        my $exit = $self->get_severity(label => 'health', section => 'disk', value => $result->{diskHealthStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Disk '%s' is '%s'", $result->{diskDescr}, $result->{diskHealthStatus})
            );
        }
    }
}

1;
