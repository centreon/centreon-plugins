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

package storage::netapp::ontap::snmp::mode::components::temperature;

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
    enclTempSensorsPresent => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.20' },
    enclTempSensorsOverTempFail => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.21' },
    enclTempSensorsOverTempWarn => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.22' },
    enclTempSensorsUnderTempFail => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.23' },
    enclTempSensorsUnderTempWarn => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.24' },
    enclTempSensorsCurrentTemp => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.25' },
    enclTempSensorsOverTempFailThr => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.26' },
    enclTempSensorsOverTempWarnThr => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.27' },
    enclTempSensorsUnderTempFailThr => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.28' },
    enclTempSensorsUnderTempWarnThr => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.29' },
};
my $oid_enclChannelShelfAddr = '.1.3.6.1.4.1.789.1.21.1.2.1.3';
my $oid_enclEntry = '.1.3.6.1.4.1.789.1.21.1.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_enclEntry, begin => $mapping->{enclTempSensorsPresent}->{oid}, end => $mapping->{enclTempSensorsUnderTempWarnThr}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    for (my $i = 1; $i <= $self->{number_shelf}; $i++) {
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_enclEntry}, instance => $i);
        my $shelf_addr = $self->{shelf_addr}->{$oid_enclChannelShelfAddr . '.' . $i};
        my @current_temp = split /,/, $result->{enclTempSensorsCurrentTemp};
        
        my @warn_under_thr = split /,/, $result->{enclTempSensorsUnderTempWarnThr};
        my @crit_under_thr = split /,/, $result->{enclTempSensorsUnderTempFailThr};
        my @warn_over_thr = split /,/, $result->{enclTempSensorsOverTempWarnThr};
        my @crit_over_thr = split /,/, $result->{enclTempSensorsOverTempFailThr};

        foreach my $num (split /,/, $result->{enclTempSensorsPresent}) {
            $num = centreon::plugins::misc::trim($num);
            next if ($num !~ /[0-9]/ || !defined($current_temp[$num - 1]));
            
            next if ($self->check_filter(section => 'temperature', instance => $shelf_addr . '.' . $num));
    
            $warn_under_thr[$num - 1] =~ /(-*[0-9]+)C/;
            my $wu_thr = $1;
            $crit_under_thr[$num - 1] =~ /(-*[0-9]+)C/;
            my $cu_thr = $1;
            $warn_over_thr[$num - 1] =~ /(-*[0-9]+)C/;
            my $wo_thr = $1;
            $crit_over_thr[$num - 1] =~ /(-*[0-9]+)C/;
            my $co_thr = $1;
            $current_temp[$num - 1] =~ /(-*[0-9]+)C/;
            my $current_value = $1;
            
            $self->{components}->{temperature}->{total}++;
            
            my $status = 'ok';
            if ($result->{enclTempSensorsUnderTempFailThr} =~ /(^|,|\s)$num(,|\s|$)/) {
                $status = 'under critical threshold';
            } elsif ($result->{enclTempSensorsUnderTempWarnThr} =~ /(^|,|\s)$num(,|\s|$)/) {
                $status = 'under warning threshold';
            } elsif ($result->{enclTempSensorsOverTempFailThr} =~ /(^|,|\s)$num(,|\s|$)/) {
                $status = 'over critical threshold';
            } elsif ($result->{enclTempSensorsOverTempWarnThr} =~ /(^|,|\s)$num(,|\s|$)/) {
                $status = 'over warning threshold';
            }
            
            $self->{output}->output_add(long_msg => sprintf("Shelve '%s' temperature sensor '%s' is %s [current = %s]", 
                                                            $shelf_addr, $num, $status, $current_value));
            my $exit = $self->get_severity(section => 'temperature', value => $status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Shelve '%s' temperature sensor '%s' is %s", 
                                                                 $shelf_addr, $num, $status));
            }
            
            my $warn = $wu_thr . ':' . $wo_thr;
            my $crit = $cu_thr . ':' . $co_thr;
            my ($exit2, $warn2, $crit2, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $shelf_addr . '.' . $num, value => $current_value);
            if ($checked == 1) { 
               ($warn, $crit) = ($warn2, $crit2);
            }
            
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Shelve '%s' temperature sensor '%s' is %s degree centigrade", 
                                                                 $shelf_addr, $num, $current_value));
            }
            
            $self->{output}->perfdata_add(
                label => "temp", unit => 'C',
                nlabel => 'hardware.temperature.celsius',
                instances => [$shelf_addr, $num],
                value => $current_value,
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
