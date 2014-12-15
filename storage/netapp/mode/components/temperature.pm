################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package storage::netapp::mode::components::temperature;

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
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_enclEntry, begin => $mapping->{enclTempSensorsPresent}->{oid}, end => $mapping->{enclTempSensorsUnderTempWarnThr}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'temperature'));

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
            next if ($num !~ /[0-9]/);
    
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
            
            next if ($self->check_exclude(section => 'temperature', instance => $shelf_addr . '.' . $num));
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
            
            $self->{output}->perfdata_add(label => "temp_" . $shelf_addr . "_" . $num, unit => 'C',
                                          value => $current_value,
                                          warning => $warn,
                                          critical => $crit);
        }
    }
}

1;