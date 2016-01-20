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

package network::dlink::standard::snmp::mode::components::temperature;

use strict;
use warnings;

# In MIB 'env_mib.mib'
my $mapping = {
    swTemperatureCurrent => { oid => '.1.3.6.1.4.1.171.12.11.1.8.1.2' },
};
my $oid_swTemperatureEntry = '.1.3.6.1.4.1.171.12.11.1.8.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_swTemperatureEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_swTemperatureEntry}})) {
        next if ($oid !~ /^$mapping->{swTemperatureCurrent}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_swTemperatureEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' is %dC.", 
                                    $instance, $result->{swTemperatureCurrent}));
        
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{swTemperatureCurrent});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' is %s degree centigrade", $instance, $result->{swTemperatureCurrent}));
        }
        $self->{output}->perfdata_add(label => "temp_" . $instance, unit => 'C',
                                      value => $result->{swTemperatureCurrent},
                                      warning => $warn,
                                      critical => $crit);
    }
}

1;