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

package hardware::sensors::serverscheck::sensorgateway::snmp::mode::components::sensors;

use strict;
use warnings;

my $oid_control = '.1.3.6.1.4.1.17095.3';
my $list_oids = {
    1 => 1,
    2 => 5,
    3 => 9,
    4 => 13,
    5 => 17,
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_control };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensors} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sensors'));

    foreach my $i (sort keys %{$list_oids}) {
        if (!defined($self->{results}->{$oid_control}->{'.1.3.6.1.4.1.17095.3.' . ($list_oids->{$i} + 1) . '.0'}) || 
            $self->{results}->{$oid_control}->{'.1.3.6.1.4.1.17095.3.' . ($list_oids->{$i} + 1) . '.0'} !~ /([0-9\.]+)/) {
            $self->{output}->output_add(long_msg => sprintf("skip sensor '%s': no values", 
                                                             $i));
            next;
        }
        
        my $name = $self->{results}->{$oid_control}->{'.1.3.6.1.4.1.17095.3.' . ($list_oids->{$i}) . '.0'};
        my $value = $self->{results}->{$oid_control}->{'.1.3.6.1.4.1.17095.3.' . ($list_oids->{$i} + 1) . '.0'};
        
        next if ($self->check_filter(section => 'sensors', instance => $name));
        $self->{components}->{sensors}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("sensor '%s' value is %s.", 
                                                        $name, $value));
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'sensors', instance => $name, value => $value);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("sensor '%s' value is %s", 
                                                             $name, $value));
        }
        $self->{output}->perfdata_add(
            label => $name,
            value => $value,
            warning => $warn,
            critical => $crit
        );
    }
}

1;
