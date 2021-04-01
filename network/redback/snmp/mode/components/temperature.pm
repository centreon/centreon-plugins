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

package network::redback::snmp::mode::components::temperature;

use strict;
use warnings;

# In MIB 'RBN-ENVMON.mib'
my $mapping = {
    rbnEntityTempDescr => { oid => '.1.3.6.1.4.1.2352.2.4.1.6.1.2' },
    rbnEntityTempCurrent => { oid => '.1.3.6.1.4.1.2352.2.4.1.6.1.3' },
};
my $oid_rbnEntityTempSensorEntry = '.1.3.6.1.4.1.2352.2.4.1.6.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_rbnEntityTempSensorEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rbnEntityTempSensorEntry}})) {
        next if ($oid !~ /^$mapping->{rbnEntityTempCurrent}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_rbnEntityTempSensorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("'%s' temperature is %dC [instance: %s].", 
                                    $result->{rbnEntityTempDescr}, $result->{rbnEntityTempCurrent},
                                    $instance));
     
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{rbnEntityTempCurrent});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' is %sC", $result->{rbnEntityTempDescr}, $result->{rbnEntityTempCurrent}));
        }
        $self->{output}->perfdata_add(
            label => "temp", unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $instance,
            value => $result->{rbnEntityTempCurrent},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
