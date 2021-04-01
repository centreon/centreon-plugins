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

package hardware::sensors::akcp::snmp::mode::components::temperature;

use strict;
use warnings;
use hardware::sensors::akcp::snmp::mode::components::resources qw(%map_default1_status %map_online %map_degree_type);

my $mapping = {
    TempDescription  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.1' }, # hhmsSensorArrayTempDescription
    TempDegree       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.3' }, # hhmsSensorArrayTempDegree
    TempStatus       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.4', map => \%map_default1_status }, # hhmsSensorArrayTempStatus
    TempOnline       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.5', map => \%map_online }, # hhmsSensorArrayTempOnline
    TempHighWarning  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.7' }, # hhmsSensorArrayTempHighWarning
    TempHighCritical => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.8' }, # hhmsSensorArrayTempHighCritical
    TempLowWarning   => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.9' }, # hhmsSensorArrayTempLowWarning
    TempLowCritical  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.10' }, # hhmsSensorArrayTempLowCritical
    TempDegreeType   => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.12', map => \%map_degree_type }, # hhmsSensorArrayTempDegreeType
};
my $mapping2 = {
    TempDescription  => { oid => '.1.3.6.1.4.1.3854.3.5.2.1.2' }, # temperatureDescription
    TempDegree       => { oid => '.1.3.6.1.4.1.3854.3.5.2.1.4' }, # temperatureDegree
    TempStatus       => { oid => '.1.3.6.1.4.1.3854.3.5.2.1.6', map => \%map_default1_status }, # temperatureStatus
    TempOnline       => { oid => '.1.3.6.1.4.1.3854.3.5.2.1.8', map => \%map_online }, # temperatureGoOffline
    TempHighWarning  => { oid => '.1.3.6.1.4.1.3854.3.5.2.1.11' }, # temperatureHighWarning
    TempHighCritical => { oid => '.1.3.6.1.4.1.3854.3.5.2.1.12' }, # temperatureHighCritical
    TempLowWarning   => { oid => '.1.3.6.1.4.1.3854.3.5.2.1.10' }, # temperatureLowWarning
    TempLowCritical  => { oid => '.1.3.6.1.4.1.3854.3.5.2.1.9' }, # temperatureLowCritical
    TempDegreeType   => { oid => '.1.3.6.1.4.1.3854.3.5.2.1.5', map => \%map_degree_type }, # temperatureUnit
};

my $oid_hhmsSensorArrayTempEntry = '.1.3.6.1.4.1.3854.1.2.2.1.16.1';
my $oid_temperatureEntry = '.1.3.6.1.4.1.3854.3.5.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hhmsSensorArrayTempEntry },
        { oid => $oid_temperatureEntry, end => $mapping2->{TempHighCritical}->{oid} };
}

sub check_temperature {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$options{entry}}})) {
        next if ($oid !~ /^$options{mapping}->{TempOnline}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{$options{entry}}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        if ($result->{TempOnline} eq 'offline') {
            $self->{output}->output_add(long_msg => sprintf("skipping '%s': is offline", $result->{TempDescription}));
            next;
        }
        $self->{components}->{temperature}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{TempDescription}, $result->{TempStatus}, $instance, 
                                    $result->{TempDegree}));
        
        my $exit = $self->get_severity(label => 'default1', section => 'temperature', value => $result->{TempStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $result->{TempDescription}, $result->{TempStatus}));
        }
             
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{TempDegree});
        if ($checked == 0) {
            $result->{TempLowWarning} = (defined($result->{TempLowWarning}) && $result->{TempLowWarning} =~ /[0-9]/) ?
                $result->{TempLowWarning} * $options{threshold_mult} : '';
            $result->{TempLowCritical} = (defined($result->{TempLowCritical}) && $result->{TempLowCritical} =~ /[0-9]/) ?
                $result->{TempLowCritical} * $options{threshold_mult} : '';
            $result->{TempHighWarning} = (defined($result->{TempHighWarning}) && $result->{TempHighWarning} =~ /[0-9]/) ?
                $result->{TempHighWarning} * $options{threshold_mult} : '';
            $result->{TempHighCritical} = (defined($result->{TempHighCritical}) && $result->{TempHighCritical} =~ /[0-9]/) ?
                $result->{TempHighCritical} * $options{threshold_mult} : '';
            my $warn_th = $result->{TempLowWarning} . ':' . $result->{TempHighWarning};
            my $crit_th = $result->{TempLowCritical} . ':' . $result->{TempHighCritical};
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
            
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Temperature '%s' is %s %s", $result->{TempDescription}, $result->{TempDegree}, $result->{TempDegreeType}->{unit}));
        }
        $self->{output}->perfdata_add(
            label => 'temperature', unit => $result->{TempDegreeType}->{unit},
            nlabel => 'hardware.sensor.temperature.' . $result->{TempDegreeType}->{unit_long},
            instances => $result->{TempDescription},
            value => $result->{TempDegree},
            warning => $warn,
            critical => $crit,
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    check_temperature($self, entry => $oid_hhmsSensorArrayTempEntry, mapping => $mapping, threshold_mult => 1);
    check_temperature($self, entry => $oid_temperatureEntry, mapping => $mapping2, threshold_mult => 0.1);
}

1;
