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

package network::raisecom::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    raisecomTemperatureValue            => { oid => '.1.3.6.1.4.1.8886.1.1.4.2.1' },
    raisecomTemperatureThresholdLow     => { oid => '.1.3.6.1.4.1.8886.1.1.4.2.5' },
    raisecomTemperatureThresholdHigh    => { oid => '.1.3.6.1.4.1.8886.1.1.4.2.6' },
};
my $oid_raisecomTemperatureEntry = '.1.3.6.1.4.1.8886.1.1.4.2';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_raisecomTemperatureEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_raisecomTemperatureEntry}})) {
        next if ($oid !~ /^$mapping->{raisecomTemperatureValue}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_raisecomTemperatureEntry}, instance => $instance);

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("temperature '%s' is %.2f C [instance: %s].",
                                    $instance, $result->{raisecomTemperatureValue}, $instance
                                    ));

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{raisecomTemperatureValue});
        if ($checked == 0) {
            my $warn_th = $result->{raisecomTemperatureThresholdLow} . ':';
            my $crit_th = ':' . $result->{raisecomTemperatureThresholdHigh};
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);

            $exit = $self->{perfdata}->threshold_check(value => $result->{raisecomTemperatureValue}, threshold => [ { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' },
                                                                                                                      { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' } ]);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        }

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' is %.2f C", $instance, $result->{raisecomTemperatureValue}));
        }
        $self->{output}->perfdata_add(
            label => 'temp', unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $instance,
            value => $result->{raisecomTemperatureValue},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
