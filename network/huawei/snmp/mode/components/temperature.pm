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

package network::huawei::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    hwEntityTemperature             => { oid => '.1.3.6.1.4.1.2011.5.25.31.1.1.1.1.11' },
    hwEntityTemperatureThreshold    => { oid => '.1.3.6.1.4.1.2011.5.25.31.1.1.1.1.12' },
};
my $oid_hwEntityStateEntry = '.1.3.6.1.4.1.2011.5.25.31.1.1.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hwEntityStateEntry, start => $mapping->{hwEntityTemperature}->{oid}, end => $mapping->{hwEntityTemperatureThreshold}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_hwEntityStateEntry}})) {
        next if ($oid !~ /^$mapping->{hwEntityTemperature}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hwEntityStateEntry}, instance => $instance);

        next if (!defined($result->{hwEntityTemperature}) || $result->{hwEntityTemperature} <= 0);
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $self->{components}->{temperature}->{total}++;

        my $name = '';
        $name = $self->get_short_name(instance => $instance) if (defined($self->{short_name}) && $self->{short_name} == 1);
        $name = $self->get_long_name(instance => $instance) unless (defined($self->{short_name}) && $self->{short_name} == 1 && defined($name) && $name ne '');

        $self->{output}->output_add(long_msg =>
            sprintf("temperature '%s' is '%s' C [instance = %s]",
                $name, $result->{hwEntityTemperature}, $instance)
        );
                
        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{hwEntityTemperature});
        if ($checked == 0 && defined($result->{hwEntityTemperatureThreshold}) && $result->{hwEntityTemperatureThreshold} > 0) {
            my $warn_th = '';
            my $crit_th = $result->{hwEntityTemperatureThreshold};
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);

            $exit = $self->{perfdata}->threshold_check(
                value => $result->{hwEntityTemperature},
                threshold => [ { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' },
                               { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' } ]);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance)
        }

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("temperature '%s' is %s C", $name, $result->{hwEntityTemperature}));
        }
        $self->{output}->perfdata_add(
            label => 'temperature', unit => 'C',
            nlabel => 'hardware.temperature.celsius',
            instances => $name,
            value => $result->{hwEntityTemperature},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
