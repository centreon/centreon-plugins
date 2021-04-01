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

package storage::netapp::ontap::snmp::mode::components::voltage;

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
    enclVoltSensorsPresent => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.35' },
    enclVoltSensorsOverVoltFail => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.36' },
    enclVoltSensorsOverVoltWarn => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.37' },
    enclVoltSensorsUnderVoltFail => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.38' },
    enclVoltSensorsUnderVoltWarn => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.39' },
    enclVoltSensorsCurrentVolt => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.40' },
    enclVoltSensorsOverVoltFailThr => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.41' },
    enclVoltSensorsOverVoltWarnThr => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.42' },
    enclVoltSensorsUnderVoltFailThr => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.43' },
    enclVoltSensorsUnderVoltWarnThr => { oid => '.1.3.6.1.4.1.789.1.21.1.2.1.44' },
};
my $oid_enclChannelShelfAddr = '.1.3.6.1.4.1.789.1.21.1.2.1.3';
my $oid_enclTable = '.1.3.6.1.4.1.789.1.21.1.2';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_enclTable, begin => $mapping->{enclVoltSensorsPresent}->{oid}, end => $mapping->{enclVoltSensorsUnderVoltWarnThr}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltage} = {name => 'voltages', total => 0, skip => 0};
    return if ($self->check_filter(section => 'voltage'));

    for (my $i = 1; $i <= $self->{number_shelf}; $i++) {
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_enclTable}, instance => $i);
        my $shelf_addr = $self->{shelf_addr}->{$oid_enclChannelShelfAddr . '.' . $i};
        my @current_volt = defined($result->{enclVoltSensorsCurrentVolt}) ? split /,/, $result->{enclVoltSensorsCurrentVolt} : ();
        
        my @warn_under_thr = defined($result->{enclVoltSensorsUnderVoltWarnThr}) ? split /,/, $result->{enclVoltSensorsUnderVoltWarnThr} : ();
        my @crit_under_thr = defined($result->{enclVoltSensorsUnderVoltFailThr}) ? split /,/, $result->{enclVoltSensorsUnderVoltFailThr} : ();
        my @warn_over_thr = defined($result->{enclVoltSensorsOverVoltWarnThr}) ? split /,/, $result->{enclVoltSensorsOverVoltWarnThr} : ();
        my @crit_over_thr = defined($result->{enclVoltSensorsOverVoltFailThr}) ? split /,/, $result->{enclVoltSensorsOverVoltFailThr} : ();

        my @values = defined($result->{enclVoltSensorsPresent}) ? split /,/, $result->{enclVoltSensorsPresent} : ();
        foreach my $num (@values) {
            $num = centreon::plugins::misc::trim($num);
            next if ($num !~ /[0-9]/ || !defined($current_volt[$num - 1]));
    
            my $wu_thr = (defined($warn_under_thr[$num - 1]) && $warn_under_thr[$num - 1] =~ /(^|\s)(-*[0-9]+)/) ? $2 : '';
            my $cu_thr = (defined($crit_under_thr[$num - 1]) && $crit_under_thr[$num - 1] =~ /(^|\s)(-*[0-9]+)/) ? $2 : '';
            my $wo_thr = (defined($warn_over_thr[$num - 1]) && $warn_over_thr[$num - 1] =~ /(^|\s)(-*[0-9]+)/) ? $2 : '';
            my $co_thr = (defined($crit_over_thr[$num - 1]) && $crit_over_thr[$num - 1] =~ /(^|\s)(-*[0-9]+)/) ? $2 : '';
            my $current_value = ($current_volt[$num - 1] =~ /(^|\s)(-*[0-9]+)/) ? $2 : '';
            
            next if ($self->check_filter(section => 'voltage', instance => $shelf_addr . '.' . $num));
            $self->{components}->{voltage}->{total}++;
            
            my $status = 'ok';
            if ($result->{enclVoltSensorsUnderVoltFailThr} =~ /(^|,|\s)$num(,|\s|$)/) {
                $status = 'under critical threshold';
            } elsif ($result->{enclVoltSensorsUnderVoltWarnThr} =~ /(^|,|\s)$num(,|\s|$)/) {
                $status = 'under warning threshold';
            } elsif ($result->{enclVoltSensorsOverVoltFailThr} =~ /(^|,|\s)$num(,|\s|$)/) {
                $status = 'over critical threshold';
            } elsif ($result->{enclVoltSensorsOverVoltWarnThr} =~ /(^|,|\s)$num(,|\s|$)/) {
                $status = 'over warning threshold';
            }
            
            $self->{output}->output_add(long_msg => sprintf("Shelve '%s' voltage sensor '%s' is %s [current = %s]", 
                                                            $shelf_addr, $num, $status, $current_value));
            my $exit = $self->get_severity(section => 'voltage', value => $status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Shelve '%s' voltage sensor '%s' is %s", 
                                                                 $shelf_addr, $num, $status));
            }
            
            my $warn = $wu_thr . ':' . $wo_thr;
            my $crit = $cu_thr . ':' . $co_thr;
            my ($exit2, $warn2, $crit2, $checked) = $self->get_severity_numeric(section => 'voltage', instance => $shelf_addr . '.' . $num, value => $current_value);
            if ($checked == 1) { 
               ($warn, $crit) = ($warn2, $crit2);
            }
            
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Shelve '%s' voltage sensor '%s' is %s mV", 
                                                                 $shelf_addr, $num, $current_value));
            }
            
            $self->{output}->perfdata_add(
                label => "volt", unit => 'mV',
                nlabel => 'hardware.voltage.millivolt',
                instances => [$shelf_addr, $num],
                value => $current_value,
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;
