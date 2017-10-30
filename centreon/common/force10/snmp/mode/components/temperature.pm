#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package centreon::common::force10::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    sseries => {
        Temp => { oid => '.1.3.6.1.4.1.6027.3.10.1.2.2.1.14' },
    },
    mseries => {
        Temp => { oid => '.1.3.6.1.4.1.6027.3.19.1.2.1.1.14' },
    },
};
my $oid_deviceSensorValueEntry = '.1.3.6.1.4.1.3417.2.1.1.1.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{sseries}->{Temp}->{oid} },
        { oid => $mapping->{mseries}->{Temp}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    foreach my $name (keys %{$mapping}) {
        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{$name}->{Temp}->{oid}}})) {
            next if ($oid !~ /^$mapping->{$name}->{Temp}->{oid}\.(.*)$/);
            my $instance = $1;
            my $result = $self->{snmp}->map_instance(mapping => $mapping->{$name}, results => $self->{results}->{$mapping->{$name}->{Temp}->{oid}}, instance => $instance);
            
            next if ($self->check_filter(section => 'temperature', instance => $instance));
            $self->{components}->{temperature}->{total}++;

            $self->{output}->output_add(long_msg => sprintf("Temperature '%s' is %s C [instance: %s]", 
                                        $instance, $result->{Temp}, 
                                        $instance));
            
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{Temp});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Temperature '%s' is %s C", $instance, $result->{Temp}));
            }
            $self->{output}->perfdata_add(label => 'temp_' . $instance, unit => 'C',
                                          value => $result->{Temp},
                                          warning => $warn,
                                          critical => $crit);
        }
    }
}

1;