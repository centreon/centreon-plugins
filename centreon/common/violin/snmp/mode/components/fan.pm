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

package centreon::common::violin::snmp::mode::components::fan;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_arrayFanEntry_speed = '.1.3.6.1.4.1.35897.1.2.2.3.18.1.3';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_arrayFanEntry_speed };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid (keys %{$self->{results}->{$oid_arrayFanEntry_speed}}) {
        $oid =~ /^$oid_arrayFanEntry_speed\.(.*)$/;
        my ($dummy, $array_name, $fan_name) = $self->convert_index(value => $1);
        my $instance = $array_name . '-' . $fan_name;
        my $fan_state = $self->{results}->{$oid_arrayFanEntry_speed}->{$oid};

        next if ($self->check_filter(section => 'fan', instance => $instance));
        next if ($fan_state =~ /Absent/i && 
                 $self->absent_problem(section => 'fan', instance => $instance));
        
        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' state is %s.",
                                    $instance, $fan_state));
        my $exit = $self->get_severity(section => 'fan', value => $fan_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' state is %s", $instance, $fan_state));
        }
    }
}

1;
