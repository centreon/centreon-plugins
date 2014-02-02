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

package storage::hp::lefthand::mode::components::voltage;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
     $self->{components}->{voltage} = {name => 'voltage sensors', total => 0};
    $self->{output}->output_add(long_msg => "Checking voltage sensors");
    return if ($self->check_exclude('voltage'));
    
    my $vs_count_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.140.0";
    my $vs_name_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.141.1.2";
    my $vs_value_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.141.1.3";
    my $vs_low_limit_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.141.1.4";
    my $vs_high_limit_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.141.1.5";
    my $vs_state_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.141.1.90";
    my $vs_status_oid = ".1.3.6.1.4.1.9804.3.1.1.2.1.141.1.91";
    return if ($self->{global_information}->{$vs_count_oid} == 0);
    
    $self->{snmp}->load(oids => [$vs_name_oid, $vs_value_oid,
                                 $vs_low_limit_oid, $vs_high_limit_oid,
                                 $vs_state_oid, $vs_status_oid],
                        begin => 1, end => $self->{global_information}->{$vs_count_oid});
    my $result = $self->{snmp}->get_leef();
    return if (scalar(keys %$result) <= 0);
    
    my $number_vs = $self->{global_information}->{$vs_count_oid};
    for (my $i = 1; $i <= $number_vs; $i++) {
        my $vs_name = $result->{$vs_name_oid . "." . $i};
        my $vs_value = $result->{$vs_value_oid . "." . $i};
        my $vs_low_limit = $result->{$vs_low_limit_oid . "." . $i};
        my $vs_high_limit = $result->{$vs_high_limit_oid . "." . $i};
        my $vs_state = $result->{$vs_state_oid . "." . $i};
        my $vs_status = $result->{$vs_status_oid . "." . $i};
        
        $self->{components}->{voltage}->{total}++;
        
        # Check Voltage limit
        if (defined($vs_low_limit) && defined($vs_high_limit)) {
            if ($vs_value <= $vs_low_limit) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Voltage sensor '" .  $vs_name . "' too low");
            } elsif ($vs_value >= $vs_high_limit) {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Voltage sensor '" .  $vs_name . "' too high");
            }
            $self->{output}->output_add(long_msg => "Voltage sensor '" .  $vs_name . "' value = '" . $vs_value  . "' (<= $vs_low_limit, >= $vs_high_limit)");
            $self->{output}->perfdata_add(label => $vs_name . "_volt",
                                          value => $vs_value,
                                          warning => '@:' . $vs_low_limit, critical => $vs_high_limit);
        }
        
        if ($vs_status != 1) {
            $self->{output}->output_add(severity => 'CRITICAL', 
                                        short_msg => "Voltage sensor '" .  $vs_name . "' problem '" . $vs_state . "'");
        }
        $self->{output}->output_add(long_msg => "Voltage sensor '" .  $vs_name . "' status = '" . $vs_status  . "', state = '" . $vs_state . "'");
    }
}

1;