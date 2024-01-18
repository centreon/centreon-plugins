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

package network::nortel::standard::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping_s5 = {
    value => { oid => '.1.3.6.1.4.1.45.1.6.3.7.1.1.5' } # s5ChasTmpSnrTmpValue
};
my $oid_s5ChasTmpSnrEntry = '.1.3.6.1.4.1.45.1.6.3.7.1.1';

my $mapping_voss = {
    description => { oid => '.1.3.6.1.4.1.2272.1.101.1.1.2.1.2' }, # rcVossSystemTemperatureSensorDescription
    value       => { oid => '.1.3.6.1.4.1.2272.1.101.1.1.2.1.3' } # rcVossSystemTemperatureTemperature
};
my $oid_vossTempEntry = '.1.3.6.1.4.1.2272.1.101.1.1.2.1'; # rcVossSystemTemperatureEntry

sub load {
    my ($self) = @_;
    
    push @{$self->{request}},
        { oid => $oid_s5ChasTmpSnrEntry, start => $mapping_s5->{value}->{oid}, end => $mapping_s5->{value}->{oid} },
        { oid => $oid_vossTempEntry, start => $mapping_voss->{description}->{oid}, end => $mapping_voss->{value}->{oid} };
}

sub check_s5 {
    my ($self) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_s5ChasTmpSnrEntry}})) {
        next if ($oid !~ /^$mapping_s5->{value}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_s5, results => $self->{results}->{$oid_s5ChasTmpSnrEntry}, instance => $instance);

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $result->{value} = sprintf("%.2f", $result->{value} / 2);
        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' is %s degree centigrade [instance: %s]",
                $instance, $result->{value}, $instance
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{value});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Temperature '%s' is %s degree centigrade", $instance, $result->{value}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.celsius',
            unit => 'C',
            instances => $instance, 
            value => $result->{value},
            warning => $warn,
            critical => $crit
        );
    }
}

sub check_voss {
    my ($self) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_vossTempEntry}})) {
        next if ($oid !~ /^$mapping_voss->{value}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_voss, results => $self->{results}->{$oid_vossTempEntry}, instance => $instance);

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' is %s degree centigrade [instance: %s]",
                $result->{description}, $result->{value}, $instance
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{value});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Temperature '%s' is %s degree centigrade", $result->{description}, $result->{value}
                )
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.celsius',
            unit => 'C',
            instances => $result->{description}, 
            value => $result->{value},
            warning => $warn,
            critical => $crit
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    check_s5($self);
    check_voss($self);
}

1;
