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

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::temperature;

use strict;
use warnings;
use centreon::plugins::misc;

sub check {
    my ($self) = @_;

    $self->{components}->{temperatures} = {name => 'temperatures', total => 0};
    $self->{output}->output_add(long_msg => "Checking temperatures");
    return if ($self->check_exclude('temperatures'));
    
    my $oid_tempEntry = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1';
    my $oid_tempDescr = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1.2';
    my $oid_tempReading = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1.3';
    my $oid_tempCritLimitHigh = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1.6';
    my $oid_tempNonCritLimitHigh = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1.7';
    my $oid_tempCritLimitLow = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1.9';
    my $oid_tempNonCritLimitLow = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1.10';
    
    my $result = $self->{snmp}->get_table(oid => $oid_tempEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_tempDescr\.(\d+)$/;
        my $instance = $1;
    
        my $temp_descr = centreon::plugins::misc($result->{$oid_tempDescr . '.' . $instance});
        my $temp_value = $result->{$oid_tempReading . '.' . $instance};
        my $temp_crit_high = $result->{$oid_tempCritLimitHigh . '.' . $instance};
        my $temp_warn_high = $result->{$oid_tempNonCritLimitHigh . '.' . $instance};
        my $temp_crit_low = $result->{$oid_tempCritLimitLow . '.' . $instance};
        my $temp_warn_low = $result->{$oid_tempNonCritLimitLow . '.' . $instance};
        
        my $warn_threshold = '';
        $warn_threshold = $temp_warn_low . ':' . $temp_warn_high;
        my $crit_threshold = '';
        $crit_threshold = $temp_crit_low . ':' . $temp_crit_high;
        
        $self->{perfdata}->threshold_validate(label => 'warning_' . $instance, value => $warn_threshold);
        $self->{perfdata}->threshold_validate(label => 'critical_' . $instance, value => $crit_threshold);
        
        my $exit = $self->{perfdata}->threshold_check(value => $temp_value, threshold => [ { label => 'critical_' . $instance, 'exit_litteral' => 'critical' }, { label => 'warning_' . $instance, exit_litteral => 'warning' } ]);
        
        $self->{components}->{temperatures}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' value is %s C.", 
                                    $temp_descr, $temp_value));
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' value is %s C", $temp_descr, $temp_value));
        }
        
        $self->{output}->perfdata_add(label => 'temp_' . $temp_descr, unit => 'C',
                                      value => $temp_value,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_' . $instance),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_' . $instance),
                                      );
    }
}

1;