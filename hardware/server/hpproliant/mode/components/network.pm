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

package hardware::server::hpproliant::mode::components::network;

use strict;
use warnings;
use centreon::plugins::misc;

my %conditions = (
    1 => ['other', 'CRITICAL'], 
    2 => ['ok', 'OK'], 
    3 => ['degraded', 'WARNING'], 
    4 => ['failed', 'CRITICAL']
);

my %map_pnic_role = (
    1 => "unknown",
    2 => "primary",
    3 => "secondary",
    4 => "member",
    5 => "txRx",
    6 => "tx",
    7 => "standby",
    8 => "none",
    255 => "notApplicable",
);
my %map_nic_state = (
    1 => "unknown",
    2 => "ok",
    3 => "standby",
    4 => "failed",
);
my %map_pnic_status = (
    1 => "unknown",
    2 => "ok",
    3 => "generalFailure",
    4 => "linkFailure",
);
my %map_lnic_status = (
    1 => "unknown",
    2 => "ok",
    3 => "primaryFailed",
    4 => "standbyFailed",
    5 => "groupFailed",
    6 => "redundancyReduced",
    7 => "redundancyLost",
);
my %map_nic_duplex = (
    1 => "unknown",
    2 => "half",
    3 => "full",
);

sub physical_nic {
    my ($self) = @_;
    # In MIB 'CPQNIC-MIB.mib'
    
    $self->{output}->output_add(long_msg => "Checking physical nics");
    $self->{components}->{pnic} = {name => 'physical nics', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'pnic'));
    
    my $oid_cpqNicIfPhysAdapterIndex = '.1.3.6.1.4.1.232.18.2.3.1.1.1';
    my $oid_cpqNicIfPhysAdapterRole = '.1.3.6.1.4.1.232.18.2.3.1.1.3';
    my $oid_cpqNicIfPhysAdapterCondition = '.1.3.6.1.4.1.232.18.2.3.1.1.12';
    my $oid_cpqNicIfPhysAdapterState = '.1.3.6.1.4.1.232.18.2.3.1.1.13';
    my $oid_cpqNicIfPhysAdapterStatus = '.1.3.6.1.4.1.232.18.2.3.1.1.14';
    my $oid_cpqNicIfPhysAdapterDuplexState = '.1.3.6.1.4.1.232.18.2.3.1.1.11';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqNicIfPhysAdapterIndex);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqNicIfPhysAdapterRole, $oid_cpqNicIfPhysAdapterCondition,
                                 $oid_cpqNicIfPhysAdapterState, $oid_cpqNicIfPhysAdapterStatus,
                                 $oid_cpqNicIfPhysAdapterDuplexState],
                        instances => [keys %$result]);
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $instance = $1;
    
        next if ($self->check_exclude(section => 'pnic', instance => $instance));
        $self->{components}->{pnic}->{total}++;
        
        my $nic_index = $result->{$key};
        my $nic_role = $result2->{$oid_cpqNicIfPhysAdapterRole . '.' . $instance};
        my $nic_condition = $result2->{$oid_cpqNicIfPhysAdapterCondition . '.' . $instance};
        my $nic_state = $result2->{$oid_cpqNicIfPhysAdapterState . '.' . $instance};
        my $nic_status = $result2->{$oid_cpqNicIfPhysAdapterStatus . '.' . $instance};
        my $nic_duplex = $result2->{$oid_cpqNicIfPhysAdapterDuplexState . '.' . $instance};
        
        $self->{output}->output_add(long_msg => sprintf("physical nic %s [duplex: %s, role: %s, state: %s, status: %s] condition is %s.", 
                                    $nic_index, $map_nic_duplex{$nic_duplex}, $map_pnic_role{$nic_role},
                                    $map_nic_state{$nic_state}, $map_pnic_status{$nic_status},
                                    ${$conditions{$nic_condition}}[0]));
        if (${$conditions{$nic_condition}}[1] ne 'OK') {
            $self->{output}->output_add(severity => ${$conditions{$nic_condition}}[1],
                                        short_msg => sprintf("physical nic %d is %s", 
                                            $nic_index, ${$conditions{$nic_condition}}[0]));
        }
    }
}

sub logical_nic {
    my ($self) = @_;
    # In MIB 'CPQNIC-MIB.mib'
    
    $self->{output}->output_add(long_msg => "Checking logical nics");
    $self->{components}->{lnic} = {name => 'logical nics', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'lnic'));
    
    my $oid_cpqNicIfLogMapIndex = '.1.3.6.1.4.1.232.18.2.2.1.1.1';
    my $oid_cpqNicIfLogMapDescription = '.1.3.6.1.4.1.232.18.2.2.1.1.3';
    my $oid_cpqNicIfLogMapAdapterCount = '.1.3.6.1.4.1.232.18.2.2.1.1.5';
    my $oid_cpqNicIfLogMapCondition = '.1.3.6.1.4.1.232.18.2.2.1.1.10';
    my $oid_cpqNicIfLogMapStatus = '.1.3.6.1.4.1.232.18.2.2.1.1.11';
    
    my $result = $self->{snmp}->get_table(oid => $oid_cpqNicIfLogMapIndex);
    return if (scalar(keys %$result) <= 0);
    
    $self->{snmp}->load(oids => [$oid_cpqNicIfLogMapDescription, $oid_cpqNicIfLogMapAdapterCount,
                                 $oid_cpqNicIfLogMapCondition, $oid_cpqNicIfLogMapStatus],
                        instances => [keys %$result]);
    my $result2 = $self->{snmp}->get_leef();
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /(\d+)$/;
        my $instance = $1;
    
        next if ($self->check_exclude(section => 'lnic', instance => $instance));
        $self->{components}->{lnic}->{total}++;
    
        my $nic_index = $result->{$key};
        my $nic_description = centreon::plugins::misc::trim($result2->{$oid_cpqNicIfLogMapDescription . '.' . $instance});
        my $nic_count = $result2->{$oid_cpqNicIfLogMapAdapterCount . '.' . $instance};
        my $nic_condition = $result2->{$oid_cpqNicIfLogMapCondition . '.' . $instance};
        my $nic_status = $result2->{$oid_cpqNicIfLogMapStatus . '.' . $instance};
        
        $self->{output}->output_add(long_msg => sprintf("logical nic %s [adapter count: %s, description: %s, status: %s] condition is %s.", 
                                    $nic_index, $nic_count, $nic_description,
                                    $map_lnic_status{$nic_status},
                                    ${$conditions{$nic_condition}}[0]));
        if (${$conditions{$nic_condition}}[0] !~ /^other|ok$/i) {
            $self->{output}->output_add(severity => ${$conditions{$nic_condition}}[1],
                                        short_msg => sprintf("logical nic %d is %s (%s)", 
                                            $nic_index, ${$conditions{$nic_condition}}[0], $map_lnic_status{$nic_status}));
        }
    }
}


1;