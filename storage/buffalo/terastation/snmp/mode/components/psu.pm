#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package storage::buffalo::terastation::snmp::::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (
    -1 => 'unknown', 1 => 'fine', 2 => 'broken',
);

my $mapping = {
    nasRPSUStatus => { oid => '.1.3.6.1.4.1.5227.27.1.8.1.2', map => \%map_psu_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{nasRPSUStatus}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking redundant power supplies");
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping->{nasRPSUStatus}->{oid} }})) {
        $oid =~ /^$mapping->{nasRPSUStatus}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{nasRPSUStatus}->{oid} }, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("redundant psu '%s' status is '%s' [instance: %s].",
                                    $instance, $result->{nasRPSUStatus}, $instance
                                    ));
        my $exit = $self->get_severity(section => 'psu', value => $result->{nasRPSUStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Redundant psu '%s' status is '%s'",
                                                             $instance, $result->{nasRPSUStatus}));
        }
    }
}

1;
