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

package network::dell::os10::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    os10ChassisTemp => { oid => '.1.3.6.1.4.1.674.11000.5000.100.4.1.1.3.1.11' }
};
my $oid_os10ChassisPPID = '.1.3.6.1.4.1.674.11000.5000.100.4.1.1.3.1.5';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{os10ChassisTemp}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

     foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping->{os10ChassisTemp}->{oid} }})) {
        $oid =~ /^$mapping->{os10ChassisTemp}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{os10ChassisTemp}->{oid} }, instance => $instance);
        my $name = $self->{results}->{$oid_os10ChassisPPID}->{$oid_os10ChassisPPID . '.' . $instance};

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "chassis temperature '%s' is %s degree centigrade [instance = %s]",
                $name,
                $result->{os10ChassisTemp},
                $instance
            )
        );
     
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{os10ChassisTemp});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "chassis temperature '%s' is %s degree centigrade",
                    $name,
                    $result->{os10ChassisTemp}
                )
            );
        }
        $self->{output}->perfdata_add(
            unit => 'C',
            nlabel => 'hardware.chassis.temperature.celsius',
            instances => $name,
            value => $result->{os10ChassisTemp},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
