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

package network::adva::fsp150::snmp::mode::components::shelf;

use strict;
use warnings;
use network::adva::fsp150::snmp::mode::components::resources qw(
    $map_admin_state $map_oper_state $oids
    get_secondary_states
);

my $mapping = {
    shelfEntityIndex      => { oid => $oids->{shelfEntityIndex} },
    shelfAdminState       => { oid => '.1.3.6.1.4.1.2544.1.12.3.1.2.1.8', map => $map_admin_state },
    shelfOperationalState => { oid => '.1.3.6.1.4.1.2544.1.12.3.1.2.1.9', map => $map_oper_state },
    shelfSecondaryState   => { oid => '.1.3.6.1.4.1.2544.1.12.3.1.2.1.10' }
};
my $oid_shelfEntry = '.1.3.6.1.4.1.2544.1.12.3.1.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_shelfEntry,
        start => $mapping->{shelfAdminState}->{oid},
        end => $mapping->{shelfSecondaryState}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking shelfs');
    $self->{components}->{shelf} = { name => 'shelfs', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'shelf'));

    $self->{results}->{$oid_shelfEntry} = { %{$self->{results}->{$oid_shelfEntry}}, %{$self->{results}->{ $oids->{shelfEntityIndex} }} };
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_shelfEntry}})) {
        next if ($oid !~ /^$mapping->{shelfAdminState}->{oid}\.(.*?)\.(.*)$/);

        my ($ne_index, $shelf_index, $instance) = ($1, $2, $1 . '.' . $2);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_shelfEntry}, instance => $instance);

        my $ne_name = $self->{results}->{ $oids->{neName} }->{ $oids->{neName} . '.' . $ne_index };
        my $entity_name = $self->{results}->{ $oids->{entPhysicalName} }->{ $oids->{entPhysicalName} . '.' . $result->{shelfEntityIndex} };
        my $name = $ne_name . ':' . $entity_name;

        if ($result->{shelfAdminState} eq 'maintenance') {
            $self->{output}->output_add(
                long_msg => sprintf("skipping shelf '%s': in maintenance mode", $name)
            );
            next;
        }

        next if ($self->check_filter(section => 'shelf', instance => $instance));
        $self->{components}->{shelf}->{total}++;

        my $secondary_states = get_secondary_states(state => $result->{shelfSecondaryState});
        $self->{output}->output_add(
            long_msg => sprintf(
                "shelf '%s' operational status is '%s' [secondary status: %s][instance: %s].",
                $name,
                $result->{shelfOperationalState},
                join(',', @$secondary_states),
                $instance
            )
        );
        my $exit = $self->get_severity(label => 'operational', section => 'shelf', value => $result->{shelfOperationalState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "shelf '%s' operational status is '%s'",
                    $name,
                    $result->{shelfOperationalState}
                )
            );
        }

        $exit = 'ok';
        foreach (@$secondary_states) {
            my $exit_tmp = $self->get_severity(label => 'secondary', section => 'shelf', instance => $instance, value => $_);
            $exit = $self->{output}->get_most_critical(status => [ $exit, $exit_tmp ]);
        }
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "shelf '%s' secondary status is '%s'",
                    $name,
                    join(',', @$secondary_states)
                )
            );
        }
    }
}

1;
