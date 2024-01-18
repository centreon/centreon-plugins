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

package network::nortel::standard::snmp::mode::components::card;

use strict;
use warnings;
use network::nortel::standard::snmp::mode::components::resources qw($map_card_status);

my $mapping_rc = {
    serial => { oid => '.1.3.6.1.4.1.2272.1.4.9.1.1.3' }, # rcCardSerialNumber
    status => { oid => '.1.3.6.1.4.1.2272.1.4.9.1.1.6', map => $map_card_status } # rcCardOperStatus
};
my $oid_rcCardEntry = '.1.3.6.1.4.1.2272.1.4.9.1.1';

my $mapping_rc2k = {
    status => { oid => '.1.3.6.1.4.1.2272.1.100.6.1.5', map => $map_card_status }, # rc2kCardFrontOperStatus
    serial => { oid => '.1.3.6.1.4.1.2272.1.100.6.1.6' } # rc2kCardFrontSerialNum
};
my $oid_rc2kCardEntry = '.1.3.6.1.4.1.2272.1.100.6.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}},
        { oid => $oid_rcCardEntry, start => $mapping_rc->{serial}->{oid}, end => $mapping_rc->{serial}->{status} },
        { oid => $oid_rc2kCardEntry, start => $mapping_rc2k->{status}->{oid}, end => $mapping_rc2k->{serial}->{status} };
}

sub check_rc {
    my ($self) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rcCardEntry}})) {
        next if ($oid !~ /^$mapping_rc->{status}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_rc, results => $self->{results}->{$oid_rcCardEntry}, instance => $instance);

        next if ($self->check_filter(section => 'card', instance => $instance));
        $self->{components}->{card}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "card '%s' status is '%s' [instance: %s]",
                $result->{serial}, $result->{status},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'card', instance => $instance, value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Card '%s' status is '%s'",
                    $result->{serial}, $result->{status}
                )
            );
        }
    }
}

sub check_rc2k {
    my ($self) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rc2kCardEntry}})) {
        next if ($oid !~ /^$mapping_rc2k->{status}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_rc2k, results => $self->{results}->{$oid_rc2kCardEntry}, instance => $instance);

        next if ($self->check_filter(section => 'card', instance => $instance));
        $self->{components}->{card}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "card '%s' status is '%s' [instance: %s]",
                $result->{serial}, $result->{status},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'card', instance => $instance, value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Card '%s' status is '%s'",
                    $result->{serial}, $result->{status}
                )
            );
        }
    }
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking cards");
    $self->{components}->{card} = {name => 'cards', total => 0, skip => 0};
    return if ($self->check_filter(section => 'card'));

    check_rc($self);
    check_rc2k($self);
}

1;
