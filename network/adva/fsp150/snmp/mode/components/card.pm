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

package network::adva::fsp150::snmp::mode::components::card;

use strict;
use warnings;
use network::adva::fsp150::snmp::mode::components::resources qw(
    $map_card_type $oids
    get_secondary_states
);

my $mapping = {
    slotEntityIndex    => { oid => '.1.3.6.1.4.1.2544.1.12.3.1.3.1.2' },
    slotCardType       => { oid => '.1.3.6.1.4.1.2544.1.12.3.1.3.1.4', map => $map_card_type },
    slotSecondaryState => { oid => '.1.3.6.1.4.1.2544.1.12.3.1.3.1.15' }
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}},
        { oid => $mapping->{slotEntityIndex}->{oid} },
        { oid => $mapping->{slotCardType}->{oid} },
        { oid => $mapping->{slotSecondaryState}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking cards');
    $self->{components}->{card} = { name => 'cards', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'card'));

    my $results = {
        %{$self->{results}->{ $mapping->{slotEntityIndex}->{oid} }},
        %{$self->{results}->{ $mapping->{slotCardType}->{oid} }},
        %{$self->{results}->{ $mapping->{slotSecondaryState}->{oid} }}
    };
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$results)) {
        next if ($oid !~ /^$mapping->{slotEntityIndex}->{oid}\.(\d+)\.(\d+)\.(\d+)$/);

        my ($ne_index, $shelf_index, $card_index, $instance) = ($1, $2, $3, $1 . '.' . $2 . '.' . $3);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        my $ne_name = $self->{results}->{ $oids->{neName} }->{ $oids->{neName} . '.' . $ne_index };
        my $entity_name = $self->{results}->{ $oids->{entPhysicalName} }->{ $oids->{entPhysicalName} . '.' . $result->{slotEntityIndex} };
        my $name = $ne_name . ':' . $entity_name;
        my $secondary_states = get_secondary_states(state => $result->{slotSecondaryState});

        my $secondary_str = join(',', @$secondary_states);
        if ($secondary_str =~ /mainteance/) {
            $self->{output}->output_add(
                long_msg => sprintf("skipping card '%s': in maintenance mode", $name)
            );
            next;
        }

        next if ($self->check_filter(section => 'card', instance => $result->{slotCardType} . '.' . $instance));
        $self->{components}->{card}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "card '%s' secondary status is '%s' [instance: %s].",
                $name,
                $secondary_str,
                $result->{slotCardType} . '.' . $instance
            )
        );

        my $exit = 'ok';
        foreach (@$secondary_states) {
            my $exit_tmp = $self->get_severity(label => 'secondary', section => 'card', instance => $result->{slotCardType} . '.' . $instance, value => $_);
            $exit = $self->{output}->get_most_critical(status => [ $exit, $exit_tmp ]);
        }
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "card '%s' secondary status is '%s'",
                    $name,
                    $secondary_str
                )
            );
        }
    }
}

1;
