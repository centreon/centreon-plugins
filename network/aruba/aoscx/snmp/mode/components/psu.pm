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

package network::aruba::aoscx::snmp::mode::components::psu;

use strict;
use warnings;

my $mapping = {
    name  => { oid => '.1.3.6.1.4.1.47196.4.1.1.3.11.2.1.1.3' }, # arubaWiredPSUName
    state => { oid => '.1.3.6.1.4.1.47196.4.1.1.3.11.2.1.1.4' }, # arubaWiredPSUState
    power => { oid => '.1.3.6.1.4.1.47196.4.1.1.3.11.2.1.1.7' }  # arubaWiredPSUInstantaneousPower
};
my $oid_arubaWiredPowerSupplyEntry = '.1.3.6.1.4.1.47196.4.1.1.3.11.2.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_arubaWiredPowerSupplyEntry,
        start => $mapping->{name}->{oid},
        end => $mapping->{power}->{oid}
    };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking power supplies');
    $self->{components}->{psu} = { name => 'psu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_arubaWiredPowerSupplyEntry}})) {
        next if ($oid !~ /^$mapping->{state}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_arubaWiredPowerSupplyEntry}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance, name => $result->{name}));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "power supply '%s' status is %s [instance: %s, power: %s W]",
                $result->{name},
                $result->{state},
                $instance,
                $result->{power}
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'psu', value => $result->{state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "power supply '%s' status is %s",
                    $result->{name}, $result->{state}
                )
            );
        }
        
        next if (!defined($result->{power}) || $result->{power} =~ /^0$/);
        
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu.power', instance => $instance, name => $result->{name}, value => $result->{power});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "power supply consumption '%s' is %s W",
                    $result->{name},
                    $result->{power}
                )
            );
        }
        $self->{output}->perfdata_add(
            unit => 'W',
            nlabel => 'hardware.psu.power.watt',
            instances => $result->{name},
            value => $result->{power},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

1;
