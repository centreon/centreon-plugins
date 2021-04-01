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

package hardware::sensors::sensorip::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_temp_status = (
    1 => 'noStatus',
    2 => 'normal',
    3 => 'highWarning',
    4 => 'highCritical',
    5 => 'lowWarning',
    6 => 'lowCritical',
    7 => 'sensorError',
);
my %map_temp_online = (
    1 => 'online',
    2 => 'offline',
);

my $mapping = {
    sensorProbeTempDescription => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.1' },
    sensorProbeTempDegree => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.3' },
    sensorProbeTempStatus => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.4', map => \%map_temp_status },
    sensorProbeTempOnline => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.5', map => \%map_temp_online },
    sensorProbeTempHighWarning => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.7' },
    sensorProbeTempHighCritical => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.8' },
    sensorProbeTempLowWarning => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.9' },
    sensorProbeTempLowCritical => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.10' },
};
my $oid_sensorProbeTempEntry = '.1.3.6.1.4.1.3854.1.2.2.1.16.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_sensorProbeTempEntry, end => $mapping->{sensorProbeTempLowCritical}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_sensorProbeTempEntry}})) {
        next if ($oid !~ /^$mapping->{sensorProbeTempDegree}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_sensorProbeTempEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        if ($result->{sensorProbeTempOnline} =~ /Offline/i) {
            $self->absent_problem(section => 'temperature', instance => $instance);
            next;
        }

        $self->{components}->{temperature}->{total}++;
        if ($result->{sensorProbeTempStatus} =~ /sensorError/i) {
            my $exit = $self->get_severity(section => 'temperature', value => $result->{sensorProbeTempStatus});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Temperature sensor '%s' status is '%s'", $result->{sensorProbeTempDescription}, $result->{sensorProbeTempStatus}));
                next;
            }
        }
              
        $self->{output}->output_add(long_msg => sprintf("Temperature sensor '%s' status is '%s' [instance = %s, value = %s]",
                                    $result->{sensorProbeTempDescription}, $result->{sensorProbeTempStatus}, $instance, $result->{sensorProbeTempDegree}));
        
        if (defined($result->{sensorProbeTempDegree}) && $result->{sensorProbeTempDegree} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{sensorProbeTempDegree});
            if ($checked == 0) {
                my $warn_th = $result->{sensorProbeTempLowWarning} . ':' . $result->{sensorProbeTempHighWarning};
                my $crit_th = $result->{sensorProbeTempLowCritical} . ':' . $result->{sensorProbeTempHighCritical};
                $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
                
                $exit = $self->{perfdata}->threshold_check(value => $result->{sensorProbeTempDegree}, threshold => [ { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' }, 
                                                                                                                     { label => 'warning-temperature-instance-' . $instance, exit_litteral => 'warning' } ]);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
            }
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Temperature sensor '%s' is %s degree centigrade", $result->{sensorProbeTempDescription}, $result->{sensorProbeTempDegree}));
            }
            $self->{output}->perfdata_add(
                label => 'temp', unit => 'C',
                nlabel => 'hardware.sensor.temperature.celsius',
                instances => $instance,
                value => $result->{sensorProbeTempDegree},
                warning => $warn,
                critical => $crit,
            );
        }
    }
}

1;
