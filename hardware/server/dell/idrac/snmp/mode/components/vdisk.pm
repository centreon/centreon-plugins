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

package hardware::server::dell::idrac::snmp::mode::components::vdisk;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_vdisk_state);

my $mapping = {
    virtualDiskState => { oid => '.1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1.4', map => \%map_vdisk_state },
    virtualDiskFQDD  => { oid => '.1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1.35' }
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $mapping->{virtualDiskState}->{oid} }, { oid => $mapping->{virtualDiskFQDD}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking virtual disks");
    $self->{components}->{vdisk} = { name => 'virtual disks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'vdisk'));

    my $snmp_result = { %{$self->{results}->{ $mapping->{virtualDiskState}->{oid} }}, %{$self->{results}->{ $mapping->{virtualDiskFQDD}->{oid} }} };
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{virtualDiskState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if ($self->check_filter(section => 'vdisk', instance => $instance));
        $self->{components}->{vdisk}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "virtual disk '%s' state is '%s' [instance = %s]",
                $result->{virtualDiskFQDD}, $result->{virtualDiskState}, $instance, 
            )
        );

        my $exit = $self->get_severity(section => 'vdisk.state', value => $result->{virtualDiskState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Virtual disk '%s' state is '%s'", $result->{virtualDiskFQDD}, $result->{virtualDiskState}
                )
            );
        }
    }
}

1;
