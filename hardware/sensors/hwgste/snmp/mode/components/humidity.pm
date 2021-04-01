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

package hardware::sensors::hwgste::snmp::mode::components::humidity;

use strict;
use warnings;
use hardware::sensors::hwgste::snmp::mode::components::resources qw($mapping);

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking humidity");
    $self->{components}->{humidity} = {name => 'humidity', total => 0, skip => 0};
    return if ($self->check_filter(section => 'humidity'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping->{branch_sensors}->{$self->{branch}} }})) {
        next if ($oid !~ /^$mapping->{$self->{branch}}->{sensState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping->{$self->{branch}}, results => $self->{results}->{ $mapping->{branch_sensors}->{$self->{branch}} }, instance => $instance);
        
        next if (!(defined($result->{sensUnit}) && $result->{sensUnit} eq '%'));
        next if ($self->check_filter(section => 'humidity', instance => $instance));
        $self->{components}->{humidity}->{total}++;
        
        $result->{sensValue} /= 10 if ($result->{sensValue} =~ /\d+/);
        
        $self->{output}->output_add(long_msg => sprintf("humidity '%s' state is '%s' [instance: %s, value: %s]", 
                                    $result->{sensName}, $result->{sensState}, $instance, $result->{sensValue}));
        my $exit = $self->get_severity(section => 'humidity', label => 'default',
                                       instance => $instance, value => $result->{sensState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("humidity '%s' state is '%s'", $result->{sensName}, $result->{sensState}));
        } 
        
        if ($result->{sensValue} =~ /\d+/) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'humidity', instance => $instance, value => $result->{sensValue});
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("humidity '%s' value is %s %s", $result->{sensName}, $result->{sensValue}, $result->{sensUnit}));
            }
            $self->{output}->perfdata_add(
                label => 'sensor', unit => '%',
                nlabel => 'hardware.sensor.humidity.percentage',
                instances => $result->{sensName},
                value => $result->{sensValue},
                warning => $warn,
                critical => $crit, min => 0, max => 100
            );
        }
    }
}

1;
