#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

my $map_status = {
    1 => 'ok', 2 => 'abnormal'
};

my $mapping_equipment = {
    swTemperatureCurrent => { oid => '.1.3.6.1.4.1.171.12.11.1.8.1.2' }
};
my $mapping_industrial = {
    description    => { oid => '.1.3.6.1.4.1.171.14.5.1.1.1.1.3' }, # dEntityExtEnvTempDescr
    current        => { oid => '.1.3.6.1.4.1.171.14.5.1.1.1.1.4' }, # dEntityExtEnvTempCurrent
    threshold_low  => { oid => '.1.3.6.1.4.1.171.14.5.1.1.1.1.5' }, # dEntityExtEnvTempThresholdLow
    threshold_high => { oid => '.1.3.6.1.4.1.171.14.5.1.1.1.1.6' }, # dEntityExtEnvTempThresholdHigh
    status         => { oid => '.1.3.6.1.4.1.171.14.5.1.1.1.1.7', map => $map_status } # dEntityExtEnvTempStatus
};
my $oid_dEntityExtEnvTempEntry = '.1.3.6.1.4.1.171.14.5.1.1.1.1';

my $mapping_common = {
    description    => { oid => '.1.3.6.1.4.1.171.17.5.1.1.1.1.3' }, # esEntityExtEnvTempDescr
    current        => { oid => '.1.3.6.1.4.1.171.17.5.1.1.1.1.4' }, # esEntityExtEnvTempCurrent
    threshold_low  => { oid => '.1.3.6.1.4.1.171.17.5.1.1.1.1.5' }, # esEntityExtEnvTempThresholdLow
    threshold_high => { oid => '.1.3.6.1.4.1.171.17.5.1.1.1.1.6' }, # esEntityExtEnvTempThresholdHigh
    status         => { oid => '.1.3.6.1.4.1.171.17.5.1.1.1.1.7', map => $map_status } # esEntityExtEnvTempStatus
};
my $oid_esEntityExtEnvTempEntry = '.1.3.6.1.4.1.171.17.5.1.1.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}},
        { oid => $mapping_equipment->{swTemperatureCurrent}->{oid} },
        { oid => $oid_dEntityExtEnvTempEntry, start => $mapping_industrial->{description}->{oid} },
        { oid => $oid_esEntityExtEnvTempEntry, start => $mapping_common->{description}->{oid} }
    ;
}

sub check_temperature_equipment {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $mapping_equipment->{swTemperatureCurrent}->{oid} }})) {
        $oid =~ /^$mapping_equipment->{swTemperatureCurrent}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_equipment, results => $self->{results}->{ $mapping_equipment->{swTemperatureCurrent}->{oid} }, instance => $instance);

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => 
            sprintf(
                "temperature '%s' is %dC.", 
                $instance,
                $result->{swTemperatureCurrent}
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{swTemperatureCurrent});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Temperature '%s' is %s degree centigrade",
                    $instance,
                    $result->{swTemperatureCurrent}
                )
            );
        }
        $self->{output}->perfdata_add(
            unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $instance,
            value => $result->{swTemperatureCurrent},
            warning => $warn,
            critical => $crit
        );
    }
}

sub check_temperature {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $options{entry} }})) {
        next if ($oid !~ /^$options{mapping}->{status}->{oid}\.(\d+)\.(\d+)$/);
        my ($unit_id, $temp_id) = ($1, $2);
        my $instance = $1 . '.' . $2;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{ $options{entry} }, instance => $instance);

        my $description = 'unit' . $unit_id . ':temp' . $temp_id;
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "temperature '%s' status is '%s' [instance: %s, description: %s, current: %s]",
                $description,
                $result->{status},
                $instance,
                $result->{description},
                $result->{current}
            )
        );
        my $exit = $self->get_severity(section => 'temperature', value => $result->{status});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity =>  $exit,
                short_msg => sprintf(
                    "temperature '%s' status is %s",
                    $description, $result->{status}
                )
            );
        }
        
        next if (!defined($result->{current}));
        
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{current});
        if ($checked == 0) {
            my $warn_th = '';
            my $crit_th = defined($result->{threshold_high}) && $result->{threshold_high} =~ /\d/ ? $result->{threshold_high} : '';
            $crit_th = $result->{threshold_low} . ':' . $crit_th if (defined($result->{threshold_low}) && $result->{threshold_low} =~ /\d/);
            
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance)
        }

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "temperature '%s' is %s degree centigrate",
                    $description,
                    $result->{current}
                )
            );
        }
        $self->{output}->perfdata_add(
            unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => ['unit' . $unit_id, 'temp' . $temp_id],
            value => $result->{current},
            warning => $warn,
            critical => $crit
        );
    }
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => 'checking temperatures');
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    check_temperature_equipment($self);
    check_temperature($self, entry => $oid_dEntityExtEnvTempEntry, mapping => $mapping_industrial);
    check_temperature($self, entry => $oid_esEntityExtEnvTempEntry, mapping => $mapping_common);
}

1;
