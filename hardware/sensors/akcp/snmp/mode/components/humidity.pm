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

package hardware::sensors::akcp::snmp::mode::components::humidity;

use strict;
use warnings;
use hardware::sensors::akcp::snmp::mode::components::resources qw(%map_default1_status %map_online);

my $mapping = {
    HumidityDescription  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.1' }, # hhmsSensorArrayHumidityDescription
    HumidityPercent      => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.3' }, # hhmsSensorArrayHumidityPercent
    HumidityStatus       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.4', map => \%map_default1_status }, # hhmsSensorArrayHumidityStatus
    HumidityOnline       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.5', map => \%map_online }, # hhmsSensorArrayHumidityOnline
    HumidityHighWarning  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.7' }, # hhmsSensorArrayHumidityHighWarning
    HumidityHighCritical => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.8' }, # hhmsSensorArrayHumidityHighCritical
    HumidityLowWarning   => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.9' }, # hhmsSensorArrayHumidityLowWarning
    HumidityLowCritical  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.10' }, # hhmsSensorArrayHumidityLowCritical
};
my $mapping2 = {
    HumidityDescription  => { oid => '.1.3.6.1.4.1.3854.3.5.3.1.2' }, # humidityDescription
    HumidityPercent      => { oid => '.1.3.6.1.4.1.3854.3.5.3.1.4' }, # humidityPercent
    HumidityStatus       => { oid => '.1.3.6.1.4.1.3854.3.5.3.1.6', map => \%map_default1_status }, # humidityStatus
    HumidityOnline       => { oid => '.1.3.6.1.4.1.3854.3.5.3.1.8', map => \%map_online }, # humidityGoOffline
    HumidityHighWarning  => { oid => '.1.3.6.1.4.1.3854.3.5.3.1.11' }, # humidityHighWarning
    HumidityHighCritical => { oid => '.1.3.6.1.4.1.3854.3.5.3.1.12' }, # humidityHighCritical
    HumidityLowWarning   => { oid => '.1.3.6.1.4.1.3854.3.5.3.1.10' }, # humidityLowWarning
    HumidityLowCritical  => { oid => '.1.3.6.1.4.1.3854.3.5.3.1.9' }, # humidityLowCritical
};

my $oid_hhmsSensorArrayHumidityEntry = '.1.3.6.1.4.1.3854.1.2.2.1.17.1';
my $oid_humidityEntry = '.1.3.6.1.4.1.3854.3.5.3.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hhmsSensorArrayHumidityEntry }, 
        { oid => $oid_humidityEntry, end => $mapping2->{HumidityHighCritical}->{oid} };
}

sub check_humidity {
    my ($self, %options) = @_;

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$options{entry}}})) {
        next if ($oid !~ /^$options{mapping}->{HumidityOnline}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}->{$options{entry}}, instance => $instance);
        
        next if ($self->check_filter(section => 'humidity', instance => $instance));
        if ($result->{HumidityOnline} eq 'offline') {
            $self->{output}->output_add(long_msg => sprintf("skipping '%s': is offline", $result->{HumidityDescription}));
            next;
        }
        $self->{components}->{humidity}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("humidity '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{HumidityDescription}, $result->{HumidityStatus}, $instance, 
                                    $result->{HumidityPercent}));
        
        my $exit = $self->get_severity(label => 'default1', section => 'humidity', value => $result->{HumidityStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Humdity '%s' status is '%s'", $result->{HumidityDescription}, $result->{HumidityStatus}));
        }
             
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'humidity', instance => $instance, value => $result->{HumidityPercent});
        if ($checked == 0) {
            $result->{HumidityLowWarning} = (defined($result->{HumidityLowWarning}) && $result->{HumidityLowWarning} =~ /[0-9]/) ?
                $result->{HumidityLowWarning} : '';
            $result->{HumidityLowCritical} = (defined($result->{HumidityLowCritical}) && $result->{HumidityLowCritical} =~ /[0-9]/) ?
                $result->{HumidityLowCritical} : '';
            $result->{HumidityHighWarning} = (defined($result->{HumidityHighWarning}) && $result->{HumidityHighWarning} =~ /[0-9]/) ?
                $result->{HumidityHighWarning} : '';
            $result->{HumidityHighCritical} = (defined($result->{HumidityHighCritical}) && $result->{HumidityHighCritical} =~ /[0-9]/) ?
                $result->{HumidityHighCritical} : '';
            my $warn_th = $result->{HumidityLowWarning} . ':' . $result->{HumidityHighWarning};
            my $crit_th = $result->{HumidityLowCritical} . ':' . $result->{HumidityHighCritical};
            $self->{perfdata}->threshold_validate(label => 'warning-humidity-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-humidity-instance-' . $instance, value => $crit_th);
            
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-humidity-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-humidity-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Humdity '%s' is %s %%", $result->{HumidityDescription}, $result->{HumidityPercent}));
        }
        $self->{output}->perfdata_add(
            label => 'humidity', unit => '%',
            nlabel => 'hardware.sensor.humidity.percentage',
            instances => $result->{HumidityDescription},
            value => $result->{HumidityPercent},
            warning => $warn,
            critical => $crit,
            min => 0, max => 100
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking humidities");
    $self->{components}->{humidity} = {name => 'humidities', total => 0, skip => 0};
    return if ($self->check_filter(section => 'humidity'));
    
    check_humidity($self, entry => $oid_hhmsSensorArrayHumidityEntry, mapping => $mapping);
    check_humidity($self, entry => $oid_humidityEntry, mapping => $mapping2);
}

1;
