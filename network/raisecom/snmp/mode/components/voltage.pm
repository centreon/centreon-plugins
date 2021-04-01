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

package network::raisecom::snmp::mode::components::voltage;

use strict;
use warnings;

my $mapping = {
    raisecomVoltValue           => { oid => '.1.3.6.1.4.1.8886.1.1.4.3.1.1.3' },
    raisecomVoltThresholdLow    => { oid => '.1.3.6.1.4.1.8886.1.1.4.3.1.1.7' },
    raisecomVoltThresholdHigh   => { oid => '.1.3.6.1.4.1.8886.1.1.4.3.1.1.8' },
};
my $oid_raisecomVoltEntry = '.1.3.6.1.4.1.8886.1.1.4.3.1.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_raisecomVoltEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_raisecomVoltEntry}})) {
        next if ($oid !~ /^$mapping->{raisecomVoltValue}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_raisecomVoltEntry}, instance => $instance);

        next if ($self->check_filter(section => 'voltage', instance => $instance));
        $self->{components}->{voltage}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("voltage '%s' is %.2f mV [instance: %s].",
                                    $instance, $result->{raisecomVoltValue}, $instance
                                    ));

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{raisecomVoltValue});
        if ($checked == 0) {
            my $warn_th = $result->{raisecomVoltThresholdLow} . ':';
            my $crit_th = ':' . $result->{raisecomVoltThresholdHigh};
            $self->{perfdata}->threshold_validate(label => 'warning-voltage-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-voltage-instance-' . $instance, value => $crit_th);

            $exit = $self->{perfdata}->threshold_check(value => $result->{raisecomVoltValue}, threshold => [ { label => 'critical-voltage-instance-' . $instance, exit_litteral => 'critical' },
                                                                                                             { label => 'warning-voltage-instance-' . $instance, exit_litteral => 'warning' } ]);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-voltage-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-voltage-instance-' . $instance);
        }

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s' is %.2f mV", $instance, $result->{raisecomVoltValue}));
        }
        $self->{output}->perfdata_add(
            label => 'volt', unit => 'mV',
            nlabel => 'hardware.voltage.volt',
            instances => $instance,
            value => $result->{raisecomVoltValue},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
