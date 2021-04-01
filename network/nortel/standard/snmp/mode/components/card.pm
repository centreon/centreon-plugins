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

package network::nortel::standard::snmp::mode::components::card;

use strict;
use warnings;
use network::nortel::standard::snmp::mode::components::resources qw($map_card_status);

my $mapping = {
    rcCardSerialNumber  => { oid => '.1.3.6.1.4.1.2272.1.4.9.1.1.3' },
    rcCardOperStatus    => { oid => '.1.3.6.1.4.1.2272.1.4.9.1.1.6', map => $map_card_status },
};
my $oid_rcCardEntry = '.1.3.6.1.4.1.2272.1.4.9.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_rcCardEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking cards");
    $self->{components}->{card} = {name => 'cards', total => 0, skip => 0};
    return if ($self->check_filter(section => 'card'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rcCardEntry}})) {
        next if ($oid !~ /^$mapping->{rcCardOperStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_rcCardEntry}, instance => $instance);

        next if ($self->check_filter(section => 'card', instance => $instance));
        $self->{components}->{card}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("card '%s' status is '%s' [instance: %s].",
                                    $result->{rcCardSerialNumber}, $result->{rcCardOperStatus},
                                    $instance
                                    ));
        my $exit = $self->get_severity(section => 'card', instance => $instance, value => $result->{rcCardOperStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Card '%s' status is '%s'",
                                                             $result->{rcCardSerialNumber}, $result->{rcCardOperStatus}));
        }
    }
}

1;