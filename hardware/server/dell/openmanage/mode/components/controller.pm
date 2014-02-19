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

package hardware::server::dell::openmanage::mode::components::controller;

use strict;
use warnings;

my %state = (
    0 => 'unknown',
    1 => 'ready', 
    2 => 'failed', 
    3 => 'online', 
    4 => 'offline',
    6 => 'degraded',
);

my %status = (
    1 => ['other', 'UNKNOWN'],
    2 => ['unknown', 'UNKNOWN'],
    3 => ['ok', 'OK'],
    4 => ['nonCritical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
    6 => ['nonRecoverable', 'CRITICAL'],
);

sub check {
    my ($self) = @_;

    # In MIB '10893.mib'
    $self->{output}->output_add(long_msg => "Checking Controllers");
    $self->{components}->{controller} = {name => 'controllers', total => 0};
    return if ($self->check_exclude('controller'));
   
    my $oid_controllerName = '.1.3.6.1.4.1.674.10893.1.20.130.1.1.2';
    my $oid_controllerState = '.1.3.6.1.4.1.674.10893.1.20.130.1.1.5';
    my $oid_controllerComponentStatus = '.1.3.6.1.4.1.674.10893.1.20.130.1.1.38';
    my $oid_controllerFWVersion = '.1.3.6.1.4.1.674.10893.1.20.130.1.1.8';

    my $result = $self->{snmp}->get_table(oid => $oid_controllerName);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_controllerState, $oid_controllerComponentStatus, $oid_controllerFWVersion],
                        instances => [keys %$result],
                        instance_regexp => '(\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $controller_Index = $1;
        
        my $controller_name = $result->{$key};
        my $controller_state = $result2->{$oid_controllerState . '.' . $controller_Index};
        my $controller_componentStatus = $result2->{$oid_controllerComponentStatus . '.' . $controller_Index};
        my $controller_FWVersion = $result2->{$oid_controllerFWVersion . '.' . $controller_Index};
        
        $self->{components}->{controller}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("controller '%s' status is '%s', state is '%s' [index: %d, firmware: %s].",
                                    $controller_name, ${$status{$controller_componentStatus}}[0], $state{$controller_state},
                                    $controller_Index, $controller_FWVersion
                                    ));

        if ($controller_componentStatus != 3) {
            $self->{output}->output_add(severity =>  ${$status{$controller_componentStatus}}[1],
                                        short_msg => sprintf("controller '%s' status is '%s' [index: %d]",
                                           $controller_name, ${$status{$controller_componentStatus}}[0], $controller_Index));
        }

    }
}

1;
