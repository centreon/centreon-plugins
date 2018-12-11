#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::mikrotik::snmp::mode::components::fan;

use strict;
use warnings;

my $mapping = {
    mtxrHlFanSpeed1 => { oid => '.1.3.6.1.4.1.14988.1.1.3.17' },
    mtxrHlFanSpeed2 => { oid => '.1.3.6.1.4.1.14988.1.1.3.18' },
};

my $oid_mtxrHealth = '.1.3.6.1.4.1.14988.1.1.3';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_mtxrHealth };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));
    
    my $instance = 0;
    my ($exit, $warn, $crit, $checked);
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_mtxrHealth}, instance => $instance);
    
    if (defined($result->{mtxrHlFanSpeed1}) && $result->{mtxrHlFanSpeed1} =~ /[0-9]+/) {
        
        $self->{output}->output_add(long_msg => sprintf("Fan '1' speed is '%s' RPM", $result->{mtxrHlFanSpeed1}));

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => '1', value => $result->{mtxrHlFanSpeed1});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '1' speed is '%s' RPM", $result->{mtxrHlFanSpeed1}));
        }
        $self->{output}->perfdata_add(label => 'fan_speed_1', unit => 'RPM', 
                                      value => $result->{mtxrHlFanSpeed1},
                                      warning => $warn,
                                      critical => $crit);
        $self->{components}->{fan}->{total}++;
    }
    if (defined($result->{mtxrHlFanSpeed2}) && $result->{mtxrHlFanSpeed2} =~ /[0-9]+/) {
        
        $self->{output}->output_add(long_msg => sprintf("Fan '2' speed is '%s' RPM", $result->{mtxrHlFanSpeed2}));

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => '2', value => $result->{mtxrHlFanSpeed2});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '2' speed is '%s' RPM", $result->{mtxrHlFanSpeed2}));
        }
        $self->{output}->perfdata_add(label => 'fan_speed_2', unit => 'RPM', 
                                      value => $result->{mtxrHlFanSpeed2},
                                      warning => $warn,
                                      critical => $crit);
        $self->{components}->{fan}->{total}++;
    }
}

1;
