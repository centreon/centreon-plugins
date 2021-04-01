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

package centreon::common::h3c::snmp::mode::components::sensor;

use strict;
use warnings;

my %map_sensor_status = (
    1 => 'notSupported',
    2 => 'normal',
    4 => 'entityAbsent',
    81 => 'sensorError',
    91 => 'hardwareFaulty',
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sensor'));

    my $mapping = {
        EntityExtErrorStatus => { oid => $self->{branch} . '.19', map => \%map_sensor_status }, 
    };
    my $mapping2 = {
        EntityExtTemperature => { oid => $self->{branch} . '.12' },
        EntityExtTemperatureThreshold => { oid => $self->{branch} . '.13' },
    };

    my @instances = $self->get_instance_class(class => { 8 => 1 });
    return if (scalar(@instances) == 0);
    
    $self->{snmp}->load(oids => [$mapping2->{EntityExtTemperature}->{oid}, $mapping2->{EntityExtTemperatureThreshold}->{oid}],
                        instances => [@instances]);
    my $results = $self->{snmp}->get_leef();
    
    my ($exit, $warn, $crit, $checked);
    foreach my $instance (sort @instances) {
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$self->{branch} . '.19'}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $results, instance => $instance);
        
        next if (!defined($result->{EntityExtErrorStatus}));
        next if ($self->check_filter(section => 'sensor', instance => $instance));
        if ($result->{EntityExtErrorStatus} =~ /entityAbsent/i) {
            $self->absent_problem(section => 'sensor', instance => $instance);
            next;
        }
        
        my $name = '';
        $name = $self->get_short_name(instance => $instance) if (defined($self->{short_name}) && $self->{short_name} == 1);
        $name = $self->get_long_name(instance => $instance) unless (defined($self->{short_name}) && $self->{short_name} == 1 && defined($name) && $name ne '');
        $self->{components}->{sensor}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Sensor '%s' status is '%s' [instance = %s]",
                                                        $name, $result->{EntityExtErrorStatus}, $instance));
        $exit = $self->get_severity(section => 'sensor', value => $result->{EntityExtErrorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Sensor '%s' status is '%s'", $name, $result->{EntityExtErrorStatus}));
        }
            
        next if (defined($result2->{EntityExtTemperature}) && $result2->{EntityExtTemperature} <= 0);
            
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result2->{EntityExtTemperature});
        if ($checked == 0 && defined($result2->{EntityExtTemperatureThreshold}) &&
            $result2->{EntityExtTemperatureThreshold} > 0 && $result2->{EntityExtTemperatureThreshold} < 65535) {
            my $crit_th = '~:' . $result2->{EntityExtTemperatureThreshold};
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => undef);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
            
            $exit = $self->{perfdata}->threshold_check(value => $result2->{EntityExtTemperature}, threshold => [ { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' }, 
                                                                                                                { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' } ]);
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature sensor '%s' is %s degree centigrade", $name, $result2->{EntityExtTemperature}));
        }
        $self->{output}->perfdata_add(
            label => 'temp', unit => 'C', 
            nlabel => 'hardware.sensor.temperature.celsius',
            instances => $instance,
            value => $result2->{EntityExtTemperature},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
