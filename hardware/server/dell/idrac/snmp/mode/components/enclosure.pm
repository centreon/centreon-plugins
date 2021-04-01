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

package hardware::server::dell::idrac::snmp::mode::components::enclosure;

use strict;
use warnings;
use hardware::server::dell::idrac::snmp::mode::components::resources qw(%map_status %map_enclosure_state);

my $mapping = {
    enclosureName            => { oid => '.1.3.6.1.4.1.674.10892.5.5.1.20.130.3.1.2' },
    enclosureState           => { oid => '.1.3.6.1.4.1.674.10892.5.5.1.20.130.3.1.4', map => \%map_enclosure_state },
    enclosureRollUpStatus    => { oid => '.1.3.6.1.4.1.674.10892.5.5.1.20.130.3.1.23', map => \%map_status }
};
my $oid_enclosureTableEntry = '.1.3.6.1.4.1.674.10892.5.5.1.20.130.3';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_enclosureTableEntry,
        start => $mapping->{enclosureName}->{oid},
        end => $mapping->{enclosureRollUpStatus}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking enclosures");
    $self->{components}->{enclosure} = {name => 'enclosures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'enclosure'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_enclosureTableEntry}})) {
        next if ($oid !~ /^$mapping->{enclosureRollUpStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_enclosureTableEntry}, instance => $instance);

        next if ($self->check_filter(section => 'enclosure', instance => $instance));
        $self->{components}->{enclosure}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "enclosure '%s' status is '%s' [instance = %s] [state = %s]",
                $result->{enclosureName}, $result->{enclosureRollUpStatus}, $instance, 
                $result->{enclosureState}
            )
        );

        my $exit = $self->get_severity(section => 'enclosure.state', value => $result->{enclosureState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Enclosure '%s' state is '%s'", $result->{enclosureName}, $result->{enclosureState}
                )
            );
            next;
        }

        $exit = $self->get_severity(label => 'default.status', section => 'enclosure.status', value => $result->{enclosureRollUpStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Enclosure '%s' status is '%s'", $result->{enclosureName}, $result->{enclosureRollUpStatus}
                )
            );
        }
    }
}

1;
