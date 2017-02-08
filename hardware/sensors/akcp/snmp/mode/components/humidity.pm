#
# Copyright 2017 Centreon (http://www.centreon.com/)
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
    hhmsSensorArrayHumidityDescription  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.1' },
    hhmsSensorArrayHumidityPercent      => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.3' },
    hhmsSensorArrayHumidityStatus       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.4', map => \%map_default1_status },
    hhmsSensorArrayHumidityOnline       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.5', map => \%map_online },
    hhmsSensorArrayHumidityHighWarning  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.7' },
    hhmsSensorArrayHumidityHighCritical => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.8' },
    hhmsSensorArrayHumidityLowWarning   => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.9' },
    hhmsSensorArrayHumidityLowCritical  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.17.1.10' },
};
my $oid_hhmsSensorArrayHumidityEntry = '.1.3.6.1.4.1.3854.1.2.2.1.17.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hhmsSensorArrayHumidityEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking humidities");
    $self->{components}->{humidity} = {name => 'humidities', total => 0, skip => 0};
    return if ($self->check_filter(section => 'humidity'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_hhmsSensorArrayHumidityEntry}})) {
        next if ($oid !~ /^$mapping->{hhmsSensorArrayHumidityOnline}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hhmsSensorArrayHumidityEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'humidity', instance => $instance));
        if ($result->{hhmsSensorArrayHumidityOnline} eq 'offline') {
            $self->{output}->output_add(long_msg => sprintf("skipping '%s': is offline", $result->{hhmsSensorArrayHumidityDescription}));
            next;
        }
        $self->{components}->{humidity}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("humidity '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{hhmsSensorArrayHumidityDescription}, $result->{hhmsSensorArrayHumidityStatus}, $instance, 
                                    $result->{hhmsSensorArrayHumidityPercent}));
        
        my $exit = $self->get_severity(label => 'default1', section => 'humidity', value => $result->{hhmsSensorArrayHumidityStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Humdity '%s' status is '%s'", $result->{hhmsSensorArrayHumidityDescription}, $result->{hhmsSensorArrayHumidityStatus}));
        }
             
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'humidity', instance => $instance, value => $result->{hhmsSensorArrayHumidityPercent});
        if ($checked == 0) {
            $result->{hhmsSensorArrayHumidityLowWarning} = (defined($result->{hhmsSensorArrayHumidityLowWarning}) && $result->{hhmsSensorArrayHumidityLowWarning} =~ /[0-9]/) ?
                $result->{hhmsSensorArrayHumidityLowWarning} : '';
            $result->{hhmsSensorArrayHumidityLowCritical} = (defined($result->{hhmsSensorArrayHumidityLowCritical}) && $result->{hhmsSensorArrayHumidityLowCritical} =~ /[0-9]/) ?
                $result->{hhmsSensorArrayHumidityLowCritical} : '';
            $result->{hhmsSensorArrayHumidityHighWarning} = (defined($result->{hhmsSensorArrayHumidityHighWarning}) && $result->{hhmsSensorArrayHumidityHighWarning} =~ /[0-9]/) ?
                $result->{hhmsSensorArrayHumidityHighWarning} : '';
            $result->{hhmsSensorArrayHumidityHighCritical} = (defined($result->{hhmsSensorArrayHumidityHighCritical}) && $result->{hhmsSensorArrayHumidityHighCritical} =~ /[0-9]/) ?
                $result->{hhmsSensorArrayHumidityHighCritical} : '';
            my $warn_th = $result->{hhmsSensorArrayHumidityLowWarning} . ':' . $result->{hhmsSensorArrayHumidityHighWarning};
            my $crit_th = $result->{hhmsSensorArrayHumidityLowCritical} . ':' . $result->{hhmsSensorArrayHumidityHighCritical};
            $self->{perfdata}->threshold_validate(label => 'warning-humidity-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-humidity-instance-' . $instance, value => $crit_th);
            
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-humidity-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-humidity-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Humdity '%s' is %s %%", $result->{hhmsSensorArrayHumidityDescription}, $result->{hhmsSensorArrayHumidityPercent}));
        }
        $self->{output}->perfdata_add(label => 'humidity_' . $result->{hhmsSensorArrayHumidityDescription}, unit => '%', 
                                      value => $result->{hhmsSensorArrayHumidityPercent},
                                      warning => $warn,
                                      critical => $crit,
                                      min => 0, max => 100);
    }
}

1;