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

package network::hp::procurve::snmp::mode::components::sensor;

use strict;
use warnings;

my %map_status = (
    1 => 'unknown', 
    2 => 'bad', 
    3 => 'warning', 
    4 => 'good',
    5 => 'not present',
);
my %object_map = (
    '.1.3.6.1.4.1.11.2.3.7.8.3.1' => 'power supply', #icfPowerSupplySensor
    '.1.3.6.1.4.1.11.2.3.7.8.3.2' => 'fan',          #icfFanSensor
    '.1.3.6.1.4.1.11.2.3.7.8.3.3' => 'temperature',  #icfTemperatureSensor
    '.1.3.6.1.4.1.11.2.3.7.8.3.4' => 'future slot',  #icfFutureSlotSensor
);

my $mapping = {
    hpicfSensorObjectId => { oid => '.1.3.6.1.4.1.11.2.14.11.1.2.6.1.2', map => \%object_map },
    hpicfSensorStatus => { oid => '.1.3.6.1.4.1.11.2.14.11.1.2.6.1.4', map => \%map_status },
    hpicfSensorDescr => { oid => '.1.3.6.1.4.1.11.2.14.11.1.2.6.1.7' },
};
my $oid_hpicfSensorEntry = '.1.3.6.1.4.1.11.2.14.11.1.2.6.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hpicfSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sensor'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_hpicfSensorEntry}})) {
        next if ($oid !~ /^$mapping->{hpicfSensorStatus}->{oid}\.(.*)$/);
        my $instance_mapping = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hpicfSensorEntry}, instance => $instance_mapping);
        my $instance = $result->{hpicfSensorObjectId} . '.' . $instance_mapping;
        
        next if ($self->check_filter(section => 'sensor', instance => $instance));
        next if ($result->{hpicfSensorStatus} =~ /not present/i && 
                 $self->absent_problem(section => 'sensor', instance => $instance));
        $self->{components}->{sensor}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("%s sensor '%s' state is %s [instance: %s].",
                                    $result->{hpicfSensorObjectId}, $instance, $result->{hpicfSensorStatus}, $instance
                                    ));
        my $exit = $self->get_severity(section => 'sensor', value => $result->{hpicfSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("%s sensor '%s' state is %s", 
                                                        $result->{hpicfSensorObjectId}, $instance, $result->{hpicfSensorStatus}));
        }
    }
}

1;
