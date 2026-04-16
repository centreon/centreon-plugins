#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package snmp_standard::mode::components::port;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_port_status = (
    1 => 'unknown', 2 => 'unused',
    3 => 'ready', 4 => 'warning',
    5 => 'failure', 6 => 'notparticipating',
    7 => 'initializing', 8 => 'bypass',
    9 => 'ols', 10 => 'other',
);

my $mapping_port = {
    connUnitPortName    => { oid => '.1.3.6.1.3.94.1.10.1.17' },
    connUnitPortStatus  => { oid => '.1.3.6.1.3.94.1.10.1.7', map => \%map_port_status },
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $mapping_port->{connUnitPortName}->{oid} }, { oid => $mapping_port->{connUnitPortStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking ports");
    $self->{components}->{port} = { name => 'ports', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'port'));

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping_port->{connUnitPortName}->{oid} }})) {
        $key =~ /^$mapping_port->{connUnitPortName}->{oid}\.(.*)/;
        my $instance = $1;
        my $name = $self->{results}->{ $mapping_port->{connUnitPortName}->{oid} }->{$key};
        my $result = $self->{snmp}->map_instance(mapping => $mapping_port, results => $self->{results}->{ $mapping_port->{connUnitPortStatus}->{oid} }, instance => $instance);

        next if ($self->check_filter(section => 'port', instance => $instance, name => $name));

        $self->{components}->{port}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "port '%s' status is %s",
                $name, $result->{connUnitPortStatus}
            )
        );
        my $exit = $self->get_severity(section => 'port', name => $name, value => $result->{connUnitPortStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Port '%s' status is %s",
                    $name,
                    $result->{connUnitPortStatus}
                )
            );
        }
    }
}

1;
