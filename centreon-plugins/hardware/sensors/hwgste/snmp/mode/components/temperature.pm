#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package hardware::sensors::hwgste::snmp::mode::components::temperature;

use strict;
use warnings;
use hardware::sensors::hwgste::snmp::mode::components::resources qw($mapping);

my $oid_sensEntry = '.1.3.6.1.4.1.21796.4.1.3.1';

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperature");
    $self->{components}->{temperature} = {name => 'temperature', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_sensEntry}})) {
        next if ($oid !~ /^$mapping->{sensState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_sensEntry}, instance => $instance);
        
        next if (!(defined($result->{sensUnit}) && $result->{sensUnit} =~ /C|F|K/i));
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' state is '%s' [instance: %s, value: %s]", 
                                    $result->{sensName}, $result->{sensState}, $instance, $result->{sensTemp}));
        my $exit = $self->get_severity(section => 'temperature', label => 'default',
                                       instance => $instance, value => $result->{sensState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("temperature '%s' state is '%s'", $result->{sensName}, $result->{sensState}));
        } 
        
        if ($result->{sensTemp} =~ /\d+/) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{sensTemp});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("temperature '%s' value is %s %s", $result->{sensName}, $result->{sensTemp}, $result->{sensUnit}));
            }
            $self->{output}->perfdata_add(label => 'sensor_' . $result->{sensName}, unit => $result->{sensUnit},
                                          value => $result->{sensTemp},
                                          warning => $warn,
                                          critical => $crit);
        }
    }
}

1;