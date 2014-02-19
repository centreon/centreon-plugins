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

package hardware::server::dell::openmanage::mode::components::connector;

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

my %busType = (
    1 => 'SCSI',
    2 => 'IDE',
    3 => 'Fibre Channel',
    4 => 'SSA',
    6 => 'USB',
    7 => 'SATA',
    8 => 'SAS',
);

sub check {
    my ($self) = @_;

    # In MIB '10893.mib'
    $self->{output}->output_add(long_msg => "Checking Connectors (Channels)");
    $self->{components}->{connector} = {name => 'connectors', total => 0};
    return if ($self->check_exclude('connector'));
   
    my $oid_channelName = '.1.3.6.1.4.1.674.10893.1.20.130.2.1.2';
    my $oid_channelState = '.1.3.6.1.4.1.674.10893.1.20.130.2.1.3';
    my $oid_channelComponentStatus = '.1.3.6.1.4.1.674.10893.1.20.130.2.1.8';
    my $oid_channelBusType = '.1.3.6.1.4.1.674.10893.1.20.130.2.1.11';

    my $result = $self->{snmp}->get_table(oid => $oid_channelName);
    return if (scalar(keys %$result) <= 0);

    $self->{snmp}->load(oids => [$oid_channelState, $oid_channelComponentStatus, $oid_channelBusType],
                        instances => [keys %$result],
                        instance_regexp => '(\d+)$');
    my $result2 = $self->{snmp}->get_leef();
    return if (scalar(keys %$result2) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $channel_Index = $1;
        
        my $channel_name = $result->{$key};
        my $channel_state = $result2->{$oid_channelState . '.' . $channel_Index};
        my $channel_componentStatus = $result2->{$oid_channelComponentStatus . '.' . $channel_Index};
        my $channel_busType = $result2->{$oid_channelBusType . '.' . $channel_Index};
        
        $self->{components}->{connector}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("connector '%s' status is '%s', state is '%s' [index: %d, bus: %s].",
                                    $channel_name, ${$status{$channel_componentStatus}}[0], $state{$channel_state},
                                    $channel_Index, $busType{$channel_busType}
                                    ));

        if ($channel_componentStatus != 3) {
            $self->{output}->output_add(severity =>  ${$status{$channel_componentStatus}}[1],
                                        short_msg => sprintf("connector '%s' status is '%s' [index: %d, bus: %s]",
                                           $channel_name, ${$status{$channel_componentStatus}}[0], $channel_Index, $busType{$channel_busType}));
        }

    }
}

1;
