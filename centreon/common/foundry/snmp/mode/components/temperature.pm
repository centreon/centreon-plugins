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

package centreon::common::foundry::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping = {
    snChasActualTemperature   => { oid => '.1.3.6.1.4.1.1991.1.1.1.1.18' },
    snChasWarningTemperature  => { oid => '.1.3.6.1.4.1.1991.1.1.1.1.19' },
    snChasShutdownTemperature => { oid => '.1.3.6.1.4.1.1991.1.1.1.1.20' }
};
my $oid_snChasGen = '.1.3.6.1.4.1.1991.1.1.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_snChasGen,
        start => $mapping->{snChasActualTemperature}->{oid},
        end => $mapping->{snChasShutdownTemperature}->{oid}
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking temperatures');
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_snChasGen}, instance => '0');
    my ($name, $instance) = ('chassi', 1);

    next if ($self->check_filter(section => 'temperature', instance => $instance));

    $self->{components}->{temperature}->{total}++;
    
    $result->{snChasActualTemperature} *= 0.5;
    $result->{snChasWarningTemperature} *= 0.5;
    $result->{snChasShutdownTemperature} *= 0.5;
    $self->{output}->output_add(
        long_msg => sprintf(
            "temperature '%s' is %s celsius [instance = %s]",
            $name, $result->{snChasActualTemperature}, $instance
        )
    );
    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{snChasActualTemperature});
    if ($checked == 0) {
        my $warn_th = defined($result->{snChasWarningTemperature}) ? $result->{snChasWarningTemperature} : '';
        my $crit_th = defined($result->{snChasShutdownTemperature}) ? $result->{snChasShutdownTemperature} : '';
        $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
        $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
            
        $exit = $self->{perfdata}->threshold_check(
            value => $result->{snChasActualTemperature}, 
            threshold => [
                { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' }, 
                { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' }
            ]
        );
        $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
        $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance)
    }
        
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "temperature '%s' is %s celsius",
                $name,
                $result->{snChasActualTemperature}
            )
        );
    }

    $self->{output}->perfdata_add(
        nlabel => 'hardware.temperature.celsius',
        unit => 'C',
        instances => $name,
        value => $result->{snChasActualTemperature},
        warning => $warn,
        critical => $crit
    );
}

1;
