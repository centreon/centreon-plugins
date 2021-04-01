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

package hardware::devices::camera::hanwha::snmp::mode::components::service;

use strict;
use warnings;

my $services = {
    '3.1.1.1' => 'alarmInput1',
    '3.1.2.1' => 'alarmInput2',
    '3.1.3.1' => 'alarmInput3',
    '3.1.4.1' => 'alarmInput4',
    '3.2.1.1' => 'relayOutput1',
    '3.2.2.1' => 'relayOutput2',
    '3.2.3.1' => 'relayOutput3',
    '3.2.4.1' => 'relayOutput4',
    '3.3.1'   => 'motionDetection',
    '3.4.1'   => 'videoAnalytics',
    '3.5.1'   => 'faceDetection',
    '3.6.1'   => 'networkDisconnection',
    '3.7.1'   => 'tampering',
    '3.8.1'   => 'audioDetection',
    '3.10.1'  => 'defocus',
    '3.11.1'  => 'fogDetection',
    '3.12.1'  => 'soundClassification',
    '3.13.1'  => 'shockDetection',
    '3.14.1'  => 'temperatureDetection',
};
my $oid_nwCam = '.1.3.6.1.4.1.36849.1.2';

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking services");
    $self->{components}->{service} = { name => 'services', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'service'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_nwCam}})) {
        next if ($oid !~ /^$oid_nwCam\.(\d+)\.(.*?)\.0$/);
        my ($product_id, $service) = ($1, $2);
        next if (!defined($services->{$service}));

        my $instance = $services->{$service};
        my $service_status = $self->{results}->{$oid_nwCam}->{$oid};
        my $service_date = defined($self->{results}->{$oid_nwCam}->{$oid_nwCam . '.' . $product_id . '.' . $service . '.1'}) ? 
            $self->{results}->{$oid_nwCam}->{$oid_nwCam . '.' . $product_id . '.' . $service . '.1'} : '-';
        
        next if ($self->check_filter(section => 'service', instance => $instance));
        
        $self->{components}->{service}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("service '%s' status is '%s' [instance = %s] [date = %s]",
                                                        $instance, $service_status, $instance, $service_date));
        my $exit = $self->get_severity(section => 'service', instance => $instance, value => $service_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("service '%s' status is '%s'", $instance, $service_status));
        }
    }
}

1;
