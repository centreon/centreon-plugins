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

package hardware::server::lenovo::xcc::snmp::mode::components::temperature;

use strict;
use warnings;
use centreon::plugins::misc;

my $mapping = {
    tempDescr               => { oid => '.1.3.6.1.4.1.19046.11.1.1.1.2.1.2' },
    tempReading             => { oid => '.1.3.6.1.4.1.19046.11.1.1.1.2.1.3' },
    tempCritLimitHigh       => { oid => '.1.3.6.1.4.1.19046.11.1.1.1.2.1.6' },
    tempNonCritLimitHigh    => { oid => '.1.3.6.1.4.1.19046.11.1.1.1.2.1.7' },
    tempCritLimitLow        => { oid => '.1.3.6.1.4.1.19046.11.1.1.1.2.1.9' },
    tempNonCritLimitLow     => { oid => '.1.3.6.1.4.1.19046.11.1.1.1.2.1.10' },
    tempHealthStatus        => { oid => '.1.3.6.1.4.1.19046.11.1.1.1.2.1.11' },
};
my $oid_tempEntry = '.1.3.6.1.4.1.19046.11.1.1.1.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_tempEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_tempEntry}})) {
        next if ($oid !~ /^$mapping->{tempDescr}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_tempEntry}, instance => $instance);

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        $result->{tempDescr} = centreon::plugins::misc::trim($result->{tempDescr});
        $self->{components}->{temperature}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is %s [instance: %s][value: %s C].",
                                    $result->{tempDescr}, $result->{tempHealthStatus}, $instance, $result->{tempReading}));

        my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{tempHealthStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $result->{tempDescr}, $result->{tempHealthStatus}));
        }

        if (defined($result->{tempReading})) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{tempReading});
            if ($checked == 0) {
                my $warn_th = ($result->{tempNonCritLimitLow} =~ /\d+(\.\d+)?/ ? $result->{tempNonCritLimitLow} : '') . ':' . ($result->{tempNonCritLimitHigh} =~ /\d+(\.\d+)?/ ? $result->{tempNonCritLimitHigh} : '');
                my $crit_th = ($result->{tempCritLimitLow} =~ /\d+(\.\d+)?/ ? $result->{tempCritLimitLow} : '') . ':' . ($result->{tempCritLimitHigh} =~ /\d+(\.\d+)?/ ? $result->{tempCritLimitHigh} : '');
                $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th) if ($warn_th ne ':');
                $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th) if ($crit_th ne ':');
                $exit = $self->{perfdata}->threshold_check(
                    value => $result->{tempReading},
                    threshold => [ { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' },
                                   { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' } ]);
                
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);    
            }
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Temperature '%s' is %s C", $result->{tempDescr}, $result->{tempReading}));
            }
            $self->{output}->perfdata_add(
                label => 'temp', unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => $result->{tempDescr},
                value => $result->{tempReading},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
