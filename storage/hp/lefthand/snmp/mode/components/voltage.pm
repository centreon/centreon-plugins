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

package storage::hp::lefthand::snmp::mode::components::voltage;

use strict;
use warnings;
use storage::hp::lefthand::snmp::mode::components::resources qw($map_status);

my $mapping = {
    infoVoltageSensorName       => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.141.1.2' },
    infoVoltageSensorValue      => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.141.1.3' },
    infoVoltageSensorLowLimit   => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.141.1.4' },
    infoVoltageSensorHighLimit  => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.141.1.5' },
    infoVoltageSensorState      => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.141.1.90' },
    infoVoltageSensorStatus     => { oid => '.1.3.6.1.4.1.9804.3.1.1.2.1.141.1.91', map => $map_status },
};
my $oid_infoVoltageSensorEntry = '.1.3.6.1.4.1.9804.3.1.1.2.1.141.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_infoVoltageSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_infoVoltageSensorEntry}})) {
        next if ($oid !~ /^$mapping->{infoTemperatureSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_infoVoltageSensorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'voltage', instance => $instance));
        
        $self->{components}->{voltage}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("voltage sensor '%s' status is '%s' [instance = %s, state = %s, voltage = %s]",
                                    $result->{infoVoltageSensorName}, $result->{infoTemperatureSensorStatus}, $instance, $result->{infoVoltageSensorState},
                                    defined($result->{infoVoltageSensorValue}) ? $result->{infoVoltageSensorValue} : '-'));
        
        my $exit = $self->get_severity(label => 'default', section => 'voltage', value => $result->{infoTemperatureSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("voltage sensor '%s' state is '%s'", $result->{infoVoltageSensorName}, $result->{infoVoltageSensorState}));
        }        
        
        next if (!defined($result->{infoVoltageSensorValue}) || $result->{infoVoltageSensorValue} !~ /[0-9]/);
        
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $instance, value => $result->{infoVoltageSensorValue});
        if ($checked == 0) {
            my $warn_th = '';
            my $crit_th = $result->{infoVoltageSensorLowLimit} . ':' . $result->{infoVoltageSensorHighLimit};
            $self->{perfdata}->threshold_validate(label => 'warning-voltage-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-voltage-instance-' . $instance, value => $crit_th);
            
            $exit = $self->{perfdata}->threshold_check(
                value => $result->{infoVoltageSensorValue}, 
                threshold => [ { label => 'critical-voltage-instance-' . $instance, exit_litteral => 'critical' }, 
                               { label => 'warning-voltage-instance-' . $instance, exit_litteral => 'warning' } ]);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-voltage-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-voltage-instance-' . $instance)
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("voltage sensor '%s' is %s V", $result->{infoVoltageSensorName}, $result->{infoVoltageSensorValue}));
        }
        $self->{output}->perfdata_add(
            label => 'voltage', unit => 'V',
            nlabel => 'hardware.voltage.volt',
            instances => $result->{infoVoltageSensorName},
            value => $result->{infoVoltageSensorValue},
            warning => $warn,
            critical => $crit,
            min => 0
        );
    }
}

1;
