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
    active_fan   => { oid => '.1.3.6.1.4.1.14988.1.1.3.9' },
    fan_speed1   => { oid => '.1.3.6.1.4.1.14988.1.1.3.17' },
    fan_speed2   => { oid => '.1.3.6.1.4.1.14988.1.1.3.18' },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, ($mapping->{active_fan}, $mapping->{fan_speed1}, $mapping->{fan_speed2});
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{active_fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fans'));
    my $instance = 0;
    my ($exit, $warn, $crit, $checked);
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);

    if(defined($result->{active_fan}) && $result->{active_fan} ne "n/a") {
        my @fans = ($result->{fan_speed1}, $result->{fan_speed2});
        for my $i (0 .. 1){
            ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $fans[$i]);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Fan " . ($i+1) . " RPM is '%s'", $fans[$i]));
            }
            $self->{output}->perfdata_add(label => ('Fan_' . ($i+1)), unit => 'RPM', 
                                        value => $fans[$i],
                                        warning => $warn,
                                        critical => $crit,
                                        );
            $self->{components}->{active_fan}->{total}++;
        }
       
    } else {
        $self->{components}->{active_fan}->{skip}++;
    }
}

1;
