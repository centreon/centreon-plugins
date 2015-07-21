#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::f5::bigip::mode::components::fan;

use strict;
use warnings;

my %map_status = (
    0 => 'bad',
    1 => 'good',
    2 => 'notPresent',
);

sub check {
    my ($self) = @_;

    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    $self->{output}->output_add(long_msg => "Checking fans");
    return if ($self->check_exclude(section => 'fan'));
    
    my $oid_sysChassisFanEntry = '.1.3.6.1.4.1.3375.2.1.3.2.1.2.1';
    my $oid_sysChassisFanStatus = '.1.3.6.1.4.1.3375.2.1.3.2.1.2.1.2';
    my $oid_sysChassisFanSpeed = '.1.3.6.1.4.1.3375.2.1.3.2.1.2.1.3';
    
    my $result = $self->{snmp}->get_table(oid => $oid_sysChassisFanEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_sysChassisFanStatus\.(\d+)$/);
        my $instance = $1;
    
        next if ($self->check_exclude(section => 'fan', instance => $instance));
    
        my $status = $result->{$oid_sysChassisFanStatus . '.' . $instance};
        my $speed = $result->{$oid_sysChassisFanSpeed . '.' . $instance};

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' status is %s.", 
                                                        $instance, $map_status{$status}));
        if ($status < 1) {
            $self->{output}->output_add(severity =>  'CRITICAL',
                                        short_msg => sprintf("Fan '%s' status is %s", 
                                                             $instance, $map_status{$status}));
        }

        $self->{output}->perfdata_add(label => "fan_" . $instance,
                                      value => $speed,
                                      );
    }   

}

1;
