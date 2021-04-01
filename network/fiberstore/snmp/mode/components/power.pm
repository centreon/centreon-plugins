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

package network::fiberstore::snmp::mode::components::power;

use strict;
use warnings;

my $map_status = {
    1 => 'noAlert', 2 => 'alert', 3 => 'unsupported'
};

sub load {
    my ($self) = @_;
    
    $self->{mapping_power} = {
        status => { oid => $self->{branch} . '.37.1.2.1.7', map => $map_status } # devMPowerAlertStatus
    };
    $self->{table_power} = $self->{branch} . '.37.1.2';
    
    push @{$self->{request}}, {
        oid => $self->{table_power},
        start => $self->{mapping_power}->{status}->{oid},
        end => $self->{mapping_power}->{status}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking powers');
    $self->{components}->{power} = { name => 'powers', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'power'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{table_power} }})) {
        next if ($oid !~ /^$self->{mapping_power}->{status}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $self->{mapping_power}, results => $self->{results}->{ $self->{table_power} }, instance => $instance);

        next if ($self->check_filter(section => 'power', instance => $instance));

        $self->{components}->{power}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "power '%s' status is '%s' [instance: %s]",
                $instance, $result->{status}, $instance
            )
        );
        my $exit = $self->get_severity(section => 'power', instance => $instance, value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Power '%s' status is '%s'", $instance, $result->{status}
                )
            );
        }
    }
}

1;
