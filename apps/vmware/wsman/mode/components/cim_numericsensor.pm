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

package apps::vmware::wsman::mode::components::cim_numericsensor;

use strict;
use warnings;
use apps::vmware::wsman::mode::components::resources qw($mapping_units $mapping_sensortype);

sub load {}

sub check {
    my ($self) = @_;
    
    my $result = $self->{wsman}->request(uri => 'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_NumericSensor', dont_quit => 1);
    
    $self->{output}->output_add(long_msg => "Checking cim numeric sensors");
    $self->{components}->{cim_numericsensor} = {name => 'numeric sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cim_numericsensor') || !defined($result));

    foreach (@{$result}) {
        my $sensor_type = defined($mapping_sensortype->{$_->{SensorType}}) ? $mapping_sensortype->{$_->{SensorType}} : 'unknown';
        my $name = defined($_->{Name}) && $_->{Name} ne '' ? $_->{Name} : $_->{ElementName};
        my $instance = $sensor_type . '_' . $name;
        
        next if ($self->check_filter(section => 'cim_numericsensor', instance => $instance));
        my $status = $self->get_status(entry => $_);
        if (!defined($status)) {
            $self->{output}->output_add(long_msg => sprintf("skipping numeric sensor '%s' : no status", $name), debug => 1);
            next;
        }
        
        $self->{components}->{cim_numericsensor}->{total}++;
        my $value = $_->{CurrentReading};
        
        $value = $value * 10 ** int($_->{UnitModifier}) if (defined($value) && $value =~ /\d/);

        $self->{output}->output_add(long_msg => sprintf("Numeric sensor '%s' status is '%s' [instance: %s, current value: %s].",
                                    $name, $status,
                                    $instance, defined($value) ? $value : '-'
                                    ));
        my $exit = $self->get_severity(section => 'cim_numericsensor', label => 'default', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Numeric sensor '%s' status is '%s'",
                                                             $name, $status));
        }
        
        
        next if (!defined($value) || $value !~ /\d/);
        
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'cim_numericsensor', instance => $instance, value => $value);
        if ($checked == 0) {
            my ($warn_th, $crit_th);
            
            $warn_th = $_->{LowerThresholdNonCritical} * 10 ** int($_->{UnitModifier}) . ':' if (defined($_->{LowerThresholdNonCritical}) &&
                $_->{LowerThresholdNonCritical} =~ /\d/);
            if (defined($warn_th)) {
                $warn_th .= ($_->{UpperThresholdNonCritical} * 10 ** int($_->{UnitModifier})) if (defined($_->{UpperThresholdNonCritical}) &&
                $_->{UpperThresholdNonCritical} =~ /\d/);
            } else {
                $warn_th = '~:' . ($_->{UpperThresholdNonCritical} * 10 ** int($_->{UnitModifier})) if (defined($_->{UpperThresholdNonCritical}) &&
                $_->{UpperThresholdNonCritical} =~ /\d/);
            }
            $crit_th = $_->{LowerThresholdCritical} * 10 ** int($_->{UnitModifier}) . ':' if (defined($_->{LowerThresholdCritical}) &&
                $_->{LowerThresholdCritical} =~ /\d/);
            if (defined($crit_th)) {
                $crit_th .= ($_->{UpperThresholdCritical} * 10 ** int($_->{UnitModifier})) if (defined($_->{UpperThresholdCritical}) &&
                $_->{UpperThresholdCritical} =~ /\d/);
            } else {
                $crit_th = '~:' . ($_->{UpperThresholdCritical} * 10 ** int($_->{UnitModifier})) if (defined($_->{UpperThresholdCritical}) &&
                $_->{UpperThresholdCritical} =~ /\d/);
            }
            $self->{perfdata}->threshold_validate(label => 'warning-cim_numericsensor-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-cim_numericsensor-instance-' . $instance, value => $crit_th);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-cim_numericsensor-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-cim_numericsensor-instance-' . $instance);
        }
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Numeric sensor '%s' value is %s %s", 
                                                             $name, $value, 
                                                             defined($mapping_units->{$_->{BaseUnits}}) ? $mapping_units->{$_->{BaseUnits}} : '-'));
        }
        
        my $min = defined($_->{MinReadable}) && $_->{MinReadable} =~ /\d/ ? $_->{MinReadable} * 10 ** int($_->{UnitModifier}) : undef;
        my $max = defined($_->{MaxReadable}) && $_->{MaxReadable} =~ /\d/ ? $_->{MaxReadable} * 10 ** int($_->{UnitModifier}) : undef;
        $self->{output}->perfdata_add(
            label => $sensor_type, unit => $mapping_units->{$_->{BaseUnits}},
            nlabel => 'hardware.sensor.' . lc($sensor_type) .  '.' . lc($mapping_units->{$_->{BaseUnits}}),
            instances => $name,
            value => $value,
            warning => $warn,
            critical => $crit,
            min => $min, max => $max
        );
    }
}

1;
