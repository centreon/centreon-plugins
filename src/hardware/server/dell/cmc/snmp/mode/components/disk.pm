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

package hardware::server::dell::cmc::snmp::mode::components::disk;

use strict;
use warnings;
use hardware::server::dell::cmc::snmp::mode::components::resources qw($map_status);

my $mapping = {
    name   => { oid => '.1.3.6.1.4.1.674.10892.2.6.1.20.130.4.1.2' }, # physicalDiskName
    status => { oid => '.1.3.6.1.4.1.674.10892.2.6.1.20.130.4.1.24', map => $map_status } # physicalDiskComponentStatus
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $mapping->{name}->{oid} }, { oid => $mapping->{status}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = { name => 'disks', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'disk'));

    my $snmp_result = {
        %{$self->{results}->{ $mapping->{name}->{oid} }},
        %{$self->{results}->{ $mapping->{status}->{oid} }}
    };
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$snmp_result)) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if ($self->check_filter(section => 'disk', instance => $instance));
        $self->{components}->{disk}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "disk '%s' status is '%s' [instance: %s]",
                $result->{name},
                $result->{status},
                $instance
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'disk', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("disk '%s' status is '%s'", $result->{name}, $result->{status})
            );
        }
    }
}

1;
