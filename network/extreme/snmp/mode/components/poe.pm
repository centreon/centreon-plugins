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

package network::extreme::snmp::mode::components::poe;

use strict;
use warnings;

my %map_poe_status = (
    1 => 'initializing',
    2 => 'operational',
    3 => 'downloadFail',
    4 => 'calibrationRequired',
    5 => 'invalidFirmware',
    6 => 'mismatchVersion',
    7 => 'updating',
    8 => 'invalidDevice',
    9 => 'notOperational',
    10 => 'other',
);

my $mapping = {
    extremePethSlotPoeStatus => { oid => '.1.3.6.1.4.1.1916.1.27.1.2.1.8', map => \%map_poe_status },
};
my $mapping2 = {
    extremePethSlotMeasuredPower => { oid => '.1.3.6.1.4.1.1916.1.27.1.2.1.14' },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{extremePethSlotPoeStatus}->{oid} },
        { oid => $mapping2->{extremePethSlotMeasuredPower}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking poes");
    $self->{components}->{poe} = { name => 'poes', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'poe'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{extremePethSlotPoeStatus}->{oid}}})) {
        $oid =~ /^$mapping->{extremePethSlotPoeStatus}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{extremePethSlotPoeStatus}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{extremePethSlotMeasuredPower}->{oid}}, instance => $instance);
        
        next if ($self->check_filter(section => 'poe', instance => $instance));

        $result2->{extremePethSlotMeasuredPower} = defined($result2->{extremePethSlotMeasuredPower}) && $result2->{extremePethSlotMeasuredPower} =~ /\d+/ ?
            sprintf("%.3f", $result2->{extremePethSlotMeasuredPower} / 1000) : 'unknown';
        
        $self->{components}->{poe}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "Poe '%s' status is '%s' [instance = %s, power = %s]",
                $instance,
                $result->{extremePethSlotPoeStatus}, 
                $instance,
                $result2->{extremePethSlotMeasuredPower}
            )
        );
        $exit = $self->get_severity(section => 'poe', value => $result->{extremePethSlotPoeStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Poe '%s' status is '%s'",
                    $instance,
                    $result->{extremePethSlotPoeStatus}
                )
            );
        }
        
        next if ($result2->{extremePethSlotMeasuredPower} !~ /\d+/);
        
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'poe', instance => $instance, value => $result2->{extremePethSlotMeasuredPower});            
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Poe '%s' is '%s' W",
                    $instance,
                    $result2->{extremePethSlotMeasuredPower}
                )
            );
        }
        $self->{output}->perfdata_add(
            label => 'poe_power', unit => 'W',
            nlabel => 'hardware.poe.power.watt',
            instances => $instance,
            value => $result2->{extremePethSlotMeasuredPower},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

1;
