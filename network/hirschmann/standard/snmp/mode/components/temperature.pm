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

package network::hirschmann::standard::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping_classic_temp = {
    temp_current     => { oid => '.1.3.6.1.4.1.248.14.2.5.1' }, # hmTemperature
    temp_upper_limit => { oid => '.1.3.6.1.4.1.248.14.2.5.2' }, # hmTempUprLimit
    temp_lower_limit => { oid => '.1.3.6.1.4.1.248.14.2.5.3' }  # hmTempLwrLimit
};
my $mapping_hios_temp = {
    temp_current     => { oid => '.1.3.6.1.4.1.248.11.10.1.5.1' }, # hm2DevMgmtTemperature
    temp_upper_limit => { oid => '.1.3.6.1.4.1.248.11.10.1.5.2' }, # hm2DevMgmtTemperatureUpperLimit
    temp_lower_limit => { oid => '.1.3.6.1.4.1.248.11.10.1.5.3' }  # hm2DevMgmtTemperatureLowerLimit
};
my $oid_classic_temp_table = '.1.3.6.1.4.1.248.14.2.5'; # hmTempTable
my $oid_hios_temp_table = '.1.3.6.1.4.1.248.11.10.1.5'; # hm2DeviceMgmtTemperatureGroup

sub load {
    my ($self) = @_;
    
    push @{$self->{myrequest}->{classic}}, 
        { oid => $oid_classic_temp_table };
    push @{$self->{myrequest}->{hios}}, 
        { oid => $oid_hios_temp_table, end => $mapping_hios_temp->{temp_lower_limit}->{oid} };
}

sub check_temp {
    my ($self, %options) = @_;

    my $instance = 0;
    my $result = $self->{snmp}->map_instance(
        mapping => $options{mapping},
        results => $options{results},
        instance => $instance
    );
    return if (!defined($result->{temp_current}));

    next if ($self->check_filter(section => 'temperature', instance => $instance));
    $self->{components}->{temperature}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            "temperature is %dC [instance: %s].", 
            $result->{temp_current},
            $instance
        )
    );
    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{temp_current});
    if ($checked == 0) {
        my $warn_th = '';
        my $crit_th = $result->{temp_lower_limit} . ':' . $result->{temp_upper_limit};
        $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
        $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
        $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
        $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
    }
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf("Temperature is %s degree centigrade", $result->{hmTemperature})
        );
    }
    $self->{output}->perfdata_add(
        nlabel => 'hardware.temperature.celsius',
        unit => 'C',
        value => $result->{temp_current},
        warning => $warn,
        critical => $crit
    );
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking temperatures');
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    check_temp($self, mapping => $mapping_classic_temp, results => $self->{results}->{$oid_classic_temp_table})
        if ($self->{os_type} eq 'classic');
    check_temp($self, mapping => $mapping_hios_temp, results => $self->{results}->{$oid_hios_temp_table})
        if ($self->{os_type} eq 'hios');
}

1;
