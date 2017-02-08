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

package hardware::sensors::akcp::snmp::mode::components::temperature;

use strict;
use warnings;
use hardware::sensors::akcp::snmp::mode::components::resources qw(%map_default1_status %map_online %map_degree_type);

my $mapping = {
    hhmsSensorArrayTempDescription  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.1' },
    hhmsSensorArrayTempDegree       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.3' },
    hhmsSensorArrayTempStatus       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.4', map => \%map_default1_status },
    hhmsSensorArrayTempOnline       => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.5', map => \%map_online },
    hhmsSensorArrayTempHighWarning  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.7' },
    hhmsSensorArrayTempHighCritical => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.8' },
    hhmsSensorArrayTempLowWarning   => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.9' },
    hhmsSensorArrayTempLowCritical  => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.10' },
    hhmsSensorArrayTempDegreeType   => { oid => '.1.3.6.1.4.1.3854.1.2.2.1.16.1.12', map => \%map_degree_type },
};
my $oid_hhmsSensorArrayTempEntry = '.1.3.6.1.4.1.3854.1.2.2.1.16.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hhmsSensorArrayTempEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_hhmsSensorArrayTempEntry}})) {
        next if ($oid !~ /^$mapping->{hhmsSensorArrayTempOnline}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hhmsSensorArrayTempEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'temperature', instance => $instance));
        if ($result->{hhmsSensorArrayTempOnline} eq 'offline') {
            $self->{output}->output_add(long_msg => sprintf("skipping '%s': is offline", $result->{hhmsSensorArrayTempDescription}));
            next;
        }
        $self->{components}->{temperature}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s] [value = %s]",
                                    $result->{hhmsSensorArrayTempDescription}, $result->{hhmsSensorArrayTempStatus}, $instance, 
                                    $result->{hhmsSensorArrayTempDegree}));
        
        my $exit = $self->get_severity(label => 'default1', section => 'temperature', value => $result->{hhmsSensorArrayTempStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' status is '%s'", $result->{hhmsSensorArrayTempDescription}, $result->{hhmsSensorArrayTempStatus}));
        }
             
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{hhmsSensorArrayTempDegree});
        if ($checked == 0) {
            $result->{hhmsSensorArrayTempLowWarning} = (defined($result->{hhmsSensorArrayTempLowWarning}) && $result->{hhmsSensorArrayTempLowWarning} =~ /[0-9]/) ?
                $result->{hhmsSensorArrayTempLowWarning} : '';
            $result->{hhmsSensorArrayTempLowCritical} = (defined($result->{hhmsSensorArrayTempLowCritical}) && $result->{hhmsSensorArrayTempLowCritical} =~ /[0-9]/) ?
                $result->{hhmsSensorArrayTempLowCritical} : '';
            $result->{hhmsSensorArrayTempHighWarning} = (defined($result->{hhmsSensorArrayTempHighWarning}) && $result->{hhmsSensorArrayTempHighWarning} =~ /[0-9]/) ?
                $result->{hhmsSensorArrayTempHighWarning} : '';
            $result->{hhmsSensorArrayTempHighCritical} = (defined($result->{hhmsSensorArrayTempHighCritical}) && $result->{hhmsSensorArrayTempHighCritical} =~ /[0-9]/) ?
                $result->{hhmsSensorArrayTempHighCritical} : '';
            my $warn_th = $result->{hhmsSensorArrayTempLowWarning} . ':' . $result->{hhmsSensorArrayTempHighWarning};
            my $crit_th = $result->{hhmsSensorArrayTempLowCritical} . ':' . $result->{hhmsSensorArrayTempHighCritical};
            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $instance, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $instance, value => $crit_th);
            
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $instance);
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit2,
                                        short_msg => sprintf("Temperature '%s' is %s %s", $result->{hhmsSensorArrayTempDescription}, $result->{hhmsSensorArrayTempDegree}, $result->{hhmsSensorArrayTempDegreeType}));
        }
        $self->{output}->perfdata_add(label => 'temperature_' . $result->{hhmsSensorArrayTempDescription}, unit => $result->{hhmsSensorArrayTempDegreeType}, 
                                      value => $result->{hhmsSensorArrayTempDegree},
                                      warning => $warn,
                                      critical => $crit,
                                      );
    }
}

1;