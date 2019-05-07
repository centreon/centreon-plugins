#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::hirschmann::standard::snmp::mode::components::temperature;

use strict;
use warnings;

# In MIB 'hmpriv.mib'
my $mapping = {
    hmTemperature => { oid => '.1.3.6.1.4.1.248.14.2.5.1' },
    hmTempUprLimit => { oid => '.1.3.6.1.4.1.248.14.2.5.2' },
    hmTempLwrLimit => { oid => '.1.3.6.1.4.1.248.14.2.5.3' },
};
my $oid_hmTempTable = '.1.3.6.1.4.1.248.14.2.5';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hmTempTable };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    return if (!defined($self->{results}->{$oid_hmTempTable}->{$mapping->{hmTemperature}->{oid} . '.0'}));
    my $instance = 0;
    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hmTempTable}, instance => $instance);
        
    next if ($self->check_filter(section => 'temperature', instance => $instance));
    $self->{components}->{temperature}->{total}++;

    $self->{output}->output_add(long_msg => sprintf("temperature is %dC [instance: %s].", 
                                                    $result->{hmTemperature},
                                                    $instance));
    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{hmTemperature});
    if ($checked == 0) {
        my $warn_th = '';
        my $crit_th = $result->{hmTempLwrLimit} . ':' . $result->{hmTempUprLimit};
        $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
        $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
        $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
        $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
    }
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Temperature is %s degree centigrade", $result->{hmTemperature}));
    }
    $self->{output}->perfdata_add(
        label => "temp", unit => 'C',
        nlabel => 'hardware.temperature.celsius',
        value => $result->{hmTemperature},
        warning => $warn,
        critical => $crit
    );
}

1;
