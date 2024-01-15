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

package network::nortel::standard::snmp::mode::components::fan;

use strict;
use warnings;
use network::nortel::standard::snmp::mode::components::resources qw($map_fan_status);

my $mapping_rc = {
    status      => { oid => '.1.3.6.1.4.1.2272.1.4.7.1.1.2', map => $map_fan_status }, # rcChasFanOperStatus
    temperature => { oid => '.1.3.6.1.4.1.2272.1.4.7.1.1.3' } # rcChasFanAmbientTemperature
};
my $oid_rcFanEntry = '.1.3.6.1.4.1.2272.1.4.7.1.1'; # rcChasFanEntry

my $mapping_voss = {
    description => { oid => '.1.3.6.1.4.1.2272.1.101.1.1.4.1.3' }, # rcVossSystemFanInfoDescription
    status      => { oid => '.1.3.6.1.4.1.2272.1.101.1.1.4.1.4', map => $map_fan_status }, # rcVossSystemFanInfoOperStatus
};
my $oid_vossFanEntry = '.1.3.6.1.4.1.2272.1.101.1.1.4.1'; # rcVossSystemFanInfoEntry

sub load {
    my ($self) = @_;
    
    push @{$self->{request}},
        { oid => $oid_rcFanEntry, end => $mapping_rc->{temperature}->{oid} },
        { oid => $oid_vossFanEntry, start => $mapping_voss->{description}->{oid}, end => $mapping_voss->{status}->{oid} };
}

sub check_fan_rc {
    my ($self) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rcFanEntry}})) {
        next if ($oid !~ /^$mapping_rc->{status}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_rc, results => $self->{results}->{$oid_rcFanEntry}, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "fan '%s' status is '%s' [instance: %s, value: %s]",
                $instance,
                $result->{status},
                $instance,
                $result->{temperature}
            )
        );
        my $exit = $self->get_severity(section => 'fan', instance => $instance, value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "Fan '%s' status is '%s'",
                    $instance, $result->{status}
                )
            );
        }
        
        my ($exit2, $warn, $crit) = $self->get_severity_numeric(section => 'fan.temperature', instance => $instance, value => $result->{temperature});        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf("Fan '%s' temperature is %s degree centigrade", $instance, $result->{temperature})
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.fan.temperature.celsius',
            unit => 'C',
            instances => $instance,
            value => $result->{temperature},
            warning => $warn,
            critical => $crit
        );
    }
}

sub check_fan_voss {
    my ($self) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_vossFanEntry}})) {
        next if ($oid !~ /^$mapping_voss->{status}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_voss, results => $self->{results}->{$oid_vossFanEntry}, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "%s status is '%s' [instance: %s]",
                $result->{description},
                $result->{status},
                $instance
            )
        );
        my $exit = $self->get_severity(section => 'fan', instance => $instance, value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "%s status is '%s'",
                     $result->{description}, $result->{status}
                )
            );
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking fans');
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    check_fan_rc($self);
    check_fan_voss($self);
}

1;
