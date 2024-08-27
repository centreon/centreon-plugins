#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::raisecom::snmp::mode::components::voltage;

use strict;
use warnings;

my $mapping = {
    raisecomVoltValue           => { oid => '.1.3.6.1.4.1.8886.1.1.4.3.1.1.3' },
    raisecomVoltThresholdLow    => { oid => '.1.3.6.1.4.1.8886.1.1.4.3.1.1.7' },
    raisecomVoltThresholdHigh   => { oid => '.1.3.6.1.4.1.8886.1.1.4.3.1.1.8' },
};
my $mapping_pon_input = {
    volt        => { oid => '.1.3.6.1.4.1.8886.1.27.4.1.1.9' },  # raisecomPowerInputvol
    lowerThres  => { oid => '.1.3.6.1.4.1.8886.1.27.4.1.1.13' }, # raisecomPowerInputvollowerThres
    upperThres  => { oid => '.1.3.6.1.4.1.8886.1.27.4.1.1.16' }, # raisecomPowerInputvolupperThres
    inputType   => { oid => '.1.3.6.1.4.1.8886.1.27.4.1.1.2' }   # raisecomPowerDeviceInputType
};
my $mapping_pon_output = {
    volt       => { oid => '.1.3.6.1.4.1.8886.1.27.4.2.1.3' }, # raisecomPowerOutputvol
    lowerThres => { oid => '.1.3.6.1.4.1.8886.1.27.4.2.1.4' }, # raisecomPowerOutputvollowerThres
    upperThres => { oid => '.1.3.6.1.4.1.8886.1.27.4.2.1.5' }  # raisecomPowerOutputvolupperThres
};

my %mapping_input_type =  ( 
    1 => 'Unknown',
    2 => 'ac', 
    3 => 'dc48', 
    4 => 'dc24',
	5 => 'dc12',
    6 => 'null', # means power device is plugged out
    7 => 'ac220',
    8 => 'ac110'
);
my %mapping_output_type =  ( 
    1 => 'Other',
    2 => '3v', 
    3 => '5v',  # unit is 0.01V 
    4 => '12v', 
	5 => '-48v' # unit is 0.1V
);

my $oid_raisecomVoltEntry = '.1.3.6.1.4.1.8886.1.1.4.3.1.1';
my $oid_PON_raisecomPowerInputEntry = '.1.3.6.1.4.1.8886.1.27.4.1.1';
my $oid_PON_raisecomPowerOutputEntry = '.1.3.6.1.4.1.8886.1.27.4.2.1';

sub load { 
}

sub check_voltage {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$options{entry}})) { # check voltage for std Raisecom device
        next if ($oid !~ /^$mapping->{raisecomVoltValue}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $options{entry}, instance => $instance);

        next if ($self->check_filter(section => 'voltage', instance => $instance));
        $self->{components}->{voltage}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "voltage '%s' is %.2f mV [instance: %s].",
                $instance, 
                $result->{raisecomVoltValue}, 
                $instance
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{raisecomVoltValue});
        if ($checked == 0) {
            my $warn_th = (defined($result->{raisecomVoltThresholdLow}) && $result->{raisecomVoltThresholdLow} != 0 ? $result->{raisecomVoltThresholdLow} . ':' : undef);
            my $crit_th = (defined($result->{raisecomVoltThresholdHigh}) && $result->{raisecomVoltThresholdHigh} != 0 ? ':' . $result->{raisecomVoltThresholdHigh} : undef); 
            $self->{perfdata}->threshold_validate(label => 'warning-voltage-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-voltage-instance-' . $instance, value => $crit_th);

            $exit = $self->{perfdata}->threshold_check(
                value => $result->{raisecomVoltValue},
                threshold => [
                    { label => 'critical-voltage-instance-' . $instance, exit_litteral => 'critical' },
                    { label => 'warning-voltage-instance-' . $instance, exit_litteral => 'warning' } 
                ]
            );
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-voltage-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-voltage-instance-' . $instance);
        }

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Voltage '%s' is %.2f mV", 
                    $instance, 
                    $result->{raisecomVoltValue}
                )
            );
        }

        $self->{output}->perfdata_add(
            unit => 'mV',
            nlabel => 'hardware.voltage.millivolt',
            instances => $instance,
            value => $result->{raisecomVoltValue},
            warning => $warn,
            critical => $crit,
        );
    }
}

sub check_voltage_input {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$options{entry}})) { # check PON input voltage
        next if ($oid !~ /^$mapping_pon_input->{volt}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $self->{snmp}->map_instance(mapping => $mapping_pon_input, results => $options{entry}, instance => $instance);
        my $type = $mapping_input_type{$result->{inputType}};
        $instance = 'input-' . $instance . '-' . $type;

        next if ($self->check_filter(section => 'voltage', instance => $instance));
        $self->{components}->{voltage}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "Input voltage '%s' is %.2f mV [instance: %s].",
                $instance, 
                $result->{volt}, 
                $instance
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{volt});
        if ($checked == 0) {
            my $warn_th = (defined($result->{lowerThres}) && $result->{lowerThres} != 0 ? $result->{lowerThres} . ':' : undef); 
            my $crit_th = (defined($result->{upperThres}) && $result->{upperThres} != 0 ? ':' . $result->{upperThres} : undef); 
            $self->{perfdata}->threshold_validate(label => 'warning-voltage-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-voltage-instance-' . $instance, value => $crit_th);

            $exit = $self->{perfdata}->threshold_check(
                value => $result->{volt}, 
                threshold => [ 
                    { label => 'critical-voltage-instance-' . $instance, exit_litteral => 'critical' },
                    { label => 'warning-voltage-instance-' . $instance, exit_litteral => 'warning' } 
                ]
            );
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-voltage-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-voltage-instance-' . $instance);
        }

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Voltage '%s' is %.2f mV", 
                    $instance, 
                    $result->{volt}
                )
            );
        }

        $self->{output}->perfdata_add(
            unit => 'mV',
            nlabel => 'hardware.voltage.input.millivolt',
            instances => $instance,
            value => $result->{volt},
            warning => $warn,
            critical => $crit,
        );
    }
}

sub check_voltage_output {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$options{entry}})) { # check PON output voltage
        next if ($oid !~ /^$mapping_pon_output->{volt}->{oid}\.(.*)\.(.*)$/);
        my ($index, $type) = ($1, $2);
        my $instance = 'output-'. $index . '-' . $mapping_output_type{$type};

        my $result = $self->{snmp}->map_instance(mapping => $mapping_pon_output, results => $options{entry}, instance => $index . '.' . $type);

        next if ($self->check_filter(section => 'voltage', instance => $instance));
        $self->{components}->{voltage}->{total}++;

        if ($type == 3) {
            $result->{volt} *= 10;
        } elsif ($type == 5) {
            $result->{volt} *= 100;
        }

        $self->{output}->output_add(
            long_msg => sprintf(
                "voltage '%s' is %.2f mV [instance: %s].",
                $instance, 
                $result->{volt}, 
                $instance
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{volt});
        if ($checked == 0) {
            my $warn_th = (defined($result->{lowerThres}) && $result->{lowerThres} != 0 ? $result->{lowerThres} . ':' : undef); 
            my $crit_th = (defined($result->{upperThres}) && $result->{upperThres} != 0 ? ':' . $result->{upperThres} : undef); 
            $self->{perfdata}->threshold_validate(label => 'warning-voltage-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-voltage-instance-' . $instance, value => $crit_th);

            $exit = $self->{perfdata}->threshold_check(
                value => $result->{volt},
                threshold => [
                    { label => 'critical-voltage-instance-' . $instance, exit_litteral => 'critical' },
                    { label => 'warning-voltage-instance-' . $instance, exit_litteral => 'warning' }
                ]
            );
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-voltage-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-voltage-instance-' . $instance);
        }

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Voltage '%s' is %.2f mV", 
                    $instance, 
                    $result->{volt}
                )
            );
        }
        $self->{output}->perfdata_add(
            unit => 'mV',
            nlabel => 'hardware.voltage.output.millivolt',
            instances => $instance,
            value => $result->{volt},
            warning => $warn,
            critical => $crit
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));

    my $result = $self->{snmp}->get_table(oid => $oid_raisecomVoltEntry);
    if (scalar(keys %{$result}) <= 0) {
        my $result_pon_input = $self->{snmp}->get_table(oid => $oid_PON_raisecomPowerInputEntry);
        my $result_pon_output = $self->{snmp}->get_table(oid => $oid_PON_raisecomPowerOutputEntry);

        check_voltage_input($self, entry => $result_pon_input);
        check_voltage_output($self, entry => $result_pon_output);
    } else {
        check_voltage($self, entry => $result);
    }
}

1;
