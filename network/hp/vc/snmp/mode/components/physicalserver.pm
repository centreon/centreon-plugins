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

package network::hp::vc::snmp::mode::components::physicalserver;

use strict;
use warnings;
use network::hp::vc::snmp::mode::components::resources qw($map_managed_status $map_reason_code);

my $mapping = {
    vcPhysicalServerManagedStatus => { oid => '.1.3.6.1.4.1.11.5.7.5.2.1.1.5.1.1.3', map => $map_managed_status },
    vcPhysicalServerReasonCode => { oid => '.1.3.6.1.4.1.11.5.7.5.2.1.1.5.1.1.10', map => $map_reason_code }
};
my $oid_vcPhysicalServerEntry = '.1.3.6.1.4.1.11.5.7.5.2.1.1.5.1.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_vcPhysicalServerEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking physical servers");
    $self->{components}->{physicalserver} = { name => 'physical servers', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'physicalserver'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_vcPhysicalServerEntry}})) {
        next if ($oid !~ /^$mapping->{vcPhysicalServerManagedStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_vcPhysicalServerEntry}, instance => $instance);

        next if ($self->check_filter(section => 'physicalserver', instance => $instance));
        $self->{components}->{physicalserver}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "physical server '%s' status is '%s' [instance: %s, reason: %s].",
                $instance, $result->{vcPhysicalServerManagedStatus},
                $instance, $result->{vcPhysicalServerReasonCode}
            )
        );
        my $exit = $self->get_severity(section => 'physicalserver', label => 'default', value => $result->{vcPhysicalServerManagedStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Physical server '%s' status is '%s'",
                    $instance, $result->{vcPhysicalServerManagedStatus}
                )
            );
        }
    }
}

1;
