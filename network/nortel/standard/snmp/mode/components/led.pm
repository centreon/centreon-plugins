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

package network::nortel::standard::snmp::mode::components::led;

use strict;
use warnings;
use network::nortel::standard::snmp::mode::components::resources qw($map_led_status);

my $mapping = {
    label  => { oid => '.1.3.6.1.4.1.2272.1.101.1.1.5.1.3' }, # rcVossSystemCardLedLabel
    status => { oid => '.1.3.6.1.4.1.2272.1.101.1.1.5.1.4', map => $map_led_status } # rcVossSystemCardLedStatus
};
my $oid_led_entry = '.1.3.6.1.4.1.2272.1.101.1.1.5.1'; # rcVossSystemCardLedEntry

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_led_entry,
        start => $mapping->{label}->{oid}
    };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking led");
    $self->{components}->{led} = {name => 'led', total => 0, skip => 0};
    return if ($self->check_filter(section => 'led'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_led_entry}})) {
        next if ($oid !~ /^$mapping->{label}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_led_entry}, instance => $instance);

        next if ($self->check_filter(section => 'led', instance => $instance));
        $self->{components}->{led}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "led '%s' status is '%s' [instance: %s].",
                $result->{label},
                $result->{status},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'led', instance => $instance, value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Led '%s' status is '%s'",
                    $result->{label}, $result->{status}
                )
            );
        }
    }
}

1;
