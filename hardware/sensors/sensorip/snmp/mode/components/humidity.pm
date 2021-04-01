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

package hardware::sensors::sensorip::snmp::mode::components::humidity;

use strict;
use warnings;

my %map_hum_status = (
    1 => 'noStatus',
    2 => 'normal',
    3 => 'highWarning',
    4 => 'highCritical',
    5 => 'lowWarning',
    6 => 'lowCritical',
    7 => 'sensorError',
);
my %map_hum_online = (
    1 => 'online',
    2 => 'offline',
);

my $mapping = {
    sensorProbeHumidityDescription => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.1' },
    sensorProbeHumidityPercent => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.3' },
    sensorProbeHumidityStatus => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.4', map => \%map_hum_status },
    sensorProbeHumidityOnline => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.5', map => \%map_hum_online },
    sensorProbeHumidityHighWarning => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.7' },
    sensorProbeHumidityHighCritical => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.8' },
    sensorProbeHumidityLowWarning => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.9' },
    sensorProbeHumidityLowCritical => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.10' },
};
my $oid_sensorProbeHumidityEntry = '.1.3.6.1.4.1.3854.1.2.2.1.17.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_sensorProbeHumidityEntry, end => $mapping->{sensorProbeHumidityLowCritical}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking humidity");
    $self->{components}->{humidity} = {name => 'humidity', total => 0, skip => 0};
    return if ($self->check_filter(section => 'humidity'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_sensorProbeHumidityEntry}})) {
        next if ($oid !~ /^$mapping->{sensorProbeHumidityPercent}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_sensorProbeHumidityEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'humidity', instance => $instance));
        if ($result->{sensorProbeHumidityOnline} =~ /Offline/i) {  
            $self->absent_problem(section => 'humidity', instance => $instance);
            next;
        }
        
        $self->{components}->{humidity}->{total}++;
        if ($result->{sensorProbeHumidityStatus} =~ /sensorError/i) {
            my $exit = $self->get_severity(section => 'humidity', value => $result->{sensorProbeHumidityStatus});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Humidity sensor '%s' status is '%s'", $result->{sensorProbeHumidityDescription}, $result->{sensorProbeTempStatus}));
                next;
            }
        }
              
        $self->{output}->output_add(long_msg => sprintf("Humidity sensor '%s' status is '%s' [instance = %s, value = %s %%]",
                                    $result->{sensorProbeHumidityDescription}, $result->{sensorProbeHumidityStatus}, $instance, $result->{sensorProbeHumidityPercent}));
        
        if (defined($result->{sensorProbeHumidityPercent}) && $result->{sensorProbeHumidityPercent} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'humidity', instance => $instance, value => $result->{sensorProbeHumidityPercent});
            if ($checked == 0) {
                my $warn_th = $result->{sensorProbeHumidityLowWarning} . ':' . $result->{sensorProbeHumidityHighWarning};
                my $crit_th = $result->{sensorProbeHumidityLowCritical} . ':' . $result->{sensorProbeHumidityHighCritical};
                $self->{perfdata}->threshold_validate(label => 'warning-humidity-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-humidity-instance-' . $instance, value => $crit_th);
                
                $exit = $self->{perfdata}->threshold_check(value => $result->{sensorProbeHumidityPercent}, threshold => [ { label => 'critical-humidity-instance-' . $instance, exit_litteral => 'critical' }, 
                                                                                                                     { label => 'warning-humidity-instance-' . $instance, exit_litteral => 'warning' } ]);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-humidity-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-humidity-instance-' . $instance)
            }
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Humidity sensor '%s' is %s %%", $result->{sensorProbeHumidityDescription}, $result->{sensorProbeHumidityPercent}));
            }
            $self->{output}->perfdata_add(
                label => 'humdity', unit => '%', 
                nlabel => 'hardware.sensor.humidity.percentage',
                instances => $instance,
                value => $result->{sensorProbeHumidityPercent},
                warning => $warn,
                critical => $crit,
                min => 0, max => 100
            );
        }
    }
}

1;
