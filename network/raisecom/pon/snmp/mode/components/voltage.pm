#
# Copyright 2022 Centreon (http://www.centreon.com/)
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
# Authors : Roman Morandell - i-Vertix
#

package network::raisecom::pon::snmp::mode::components::voltage;

use strict;
use warnings;

my %map_output_status = (
    1 => 'normal', 2 => 'abnormal', 3 => 'null',
    4 => 'highAlarm', 5 => 'lowAlarm'
);

my $mapping_output = {
    raisecomPowerStatus    => { oid => '.1.3.6.1.4.1.8886.1.27.4.2.1.2', map => \%map_output_status },
    raisecomPowerOutputvol => { oid => '.1.3.6.1.4.1.8886.1.27.4.2.1.3' }
};

my $oid_raisecomOutputEntry = '.1.3.6.1.4.1.8886.1.27.4.2.1';

my %map_input_status = (
    1 => 'normal', 2 => 'lowMin', 3 => 'lowMaj',
    4 => 'lowCri', 5 => 'uppMin', 6 => 'uppMaj', 7 => 'uppCri'
);

my $mapping_input = {
    raisecomPowerStatus    => { oid => '.1.3.6.1.4.1.8886.1.27.4.1.1.10', map => \%map_input_status },
    raisecomPowerInputvol => { oid => '.1.3.6.1.4.1.8886.1.27.4.1.1.9' }
};

my $oid_raisecomInputEntry = '.1.3.6.1.4.1.8886.1.27.4.1.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_raisecomOutputEntry };
    push @{$self->{request}}, { oid => $oid_raisecomInputEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking output voltages");
    $self->{components}->{voltage} = { name => 'voltages', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'voltage_output'));

    my ($exit, $warn, $crit, $checked);

    # check output
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_raisecomOutputEntry}})) {
        next if ($oid !~ /^$mapping_output->{raisecomPowerStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $instance_id =  substr($instance, 0, index($instance, "."));

        my $result = $self->{snmp}->map_instance(mapping => $mapping_output, results => $self->{results}->{$oid_raisecomOutputEntry}, instance => $instance);

        next if ($self->check_filter(section => 'voltage_output', instance => $instance_id));
        $self->{components}->{voltage}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "Power Output '%s' status is '%s' [instance: %s, voltage is %.2f mV]",
                $instance_id,
                $result->{raisecomPowerStatus},
                $instance_id,
                defined($result->{raisecomPowerOutputvol}) ? $result->{raisecomPowerOutputvol} : 'unknown'
            )
        );
        $exit = $self->get_severity(section => 'voltage_output', value => $result->{raisecomPowerStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf("Power Output '%s' status is '%s'", $instance_id, $result->{raisecomPowerStatus})
            );
        }

        next if (!defined($result->{raisecomPowerOutputvol}) || $result->{raisecomPowerOutputvol} !~ /[0-9]+/);

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage_output', instance => $instance_id, value => $result->{raisecomPowerOutputvol});

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                short_msg                        => sprintf("Voltage '%s' is %.2f mV", "Power Output $instance_id", $result->{raisecomPowerOutputvol}));
        }
        $self->{output}->perfdata_add(
            label     => 'volt_output', unit => 'mV',
            nlabel    => 'hardware.voltage.volt',
            instances => $instance_id,
            value     => $result->{raisecomPowerOutputvol},
            warning   => $warn,
            critical  => $crit,
        );
    }

    $self->{output}->output_add(long_msg => "Checking input voltages");
    $self->{components}->{voltage} = { name => 'voltages', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'voltage_input'));

    # check input
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_raisecomInputEntry}})) {
        next if ($oid !~ /^$mapping_input->{raisecomPowerStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_input, results => $self->{results}->{$oid_raisecomInputEntry}, instance => $instance);

        next if ($self->check_filter(section => 'voltage_input', instance => $instance));
        $self->{components}->{voltage}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "Power Input '%s' status is '%s' [instance: %s, voltage is %.2f mV]",
                $instance,
                $result->{raisecomPowerStatus},
                $instance,
                defined($result->{raisecomPowerInputvol}) ? $result->{raisecomPowerInputvol} : 'unknown'
            )
        );
        $exit = $self->get_severity(section => 'voltage_input', value => $result->{raisecomPowerStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf("Power Input '%s' status is '%s'", $instance, $result->{raisecomPowerStatus})
            );
        }

        next if (!defined($result->{raisecomPowerInputvol}) || $result->{raisecomPowerInputvol} !~ /[0-9]+/);

        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage_input', instance => $instance, value => $result->{raisecomPowerInputvol});

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                short_msg                        => sprintf("Voltage '%s' is %.2f mV", "Power Input $instance", $result->{raisecomPowerInputvol}));
        }
        $self->{output}->perfdata_add(
            label     => 'volt_input', unit => 'mV',
            nlabel    => 'hardware.voltage.volt',
            instances => $instance,
            value     => $result->{raisecomPowerInputvol},
            warning   => $warn,
            critical  => $crit,
        );
    }
}

1;
