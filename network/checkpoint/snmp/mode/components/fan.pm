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

package network::checkpoint::snmp::mode::components::fan;

use strict;
use warnings;

my %map_states_fan = (
    0 => 'false',
    1 => 'true',
    2 => 'reading error',
);

my $mapping = {
    fanSpeedSensorName => { oid => '.1.3.6.1.4.1.2620.1.6.7.8.2.1.2' },
    fanSpeedSensorValue => { oid => '.1.3.6.1.4.1.2620.1.6.7.8.2.1.3' },
    fanSpeedSensorStatus => { oid => '.1.3.6.1.4.1.2620.1.6.7.8.2.1.6', map => \%map_states_fan },
};
my $oid_fanSpeedSensorEntry = '.1.3.6.1.4.1.2620.1.6.7.8.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_fanSpeedSensorEntry, start => $mapping->{fanSpeedSensorName}->{oid}, end => $mapping->{fanSpeedSensorStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fanSpeedSensorEntry}})) {
        next if ($oid !~ /^$mapping->{fanSpeedSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fanSpeedSensorEntry}, instance => $instance);
    
        next if ($self->check_filter(section => 'fan', instance => $instance));
        # can be SysFAN(J4)
        next if ($result->{fanSpeedSensorName} !~ /^[\(\)0-9a-zA-Z ]+$/); # sometimes there is some wrong values in hex 

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' sensor out of range status is '%s'",
                                    $result->{fanSpeedSensorName}, $result->{fanSpeedSensorStatus}));
        my $exit = $self->get_severity(section => 'fan', value => $result->{fanSpeedSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' sensor out of range status is '%s'", $result->{fanSpeedSensorName}, $result->{fanSpeedSensorStatus}));
        }

        if (defined($result->{fanSpeedSensorValue}) && $result->{fanSpeedSensorValue} =~ /^[0-9\.]+$/) {
            $self->{output}->perfdata_add(
                label => 'fan_speed', unit => 'rpm',
                nlabel => 'hardware.fan.speed.rpm',
                instances => [$result->{fanSpeedSensorName}, $instance],
                value => sprintf("%d", $result->{fanSpeedSensorValue})
            );
        }
    }
}

1;
