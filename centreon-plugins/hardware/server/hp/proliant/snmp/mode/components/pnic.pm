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

package hardware::server::hp::proliant::snmp::mode::components::pnic;

use strict;
use warnings;

my %map_pnic_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
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
my %map_nic_duplex = (
    1 => "unknown",
    2 => "half",
    3 => "full",
);
# In MIB 'CPQNIC-MIB.mib'
my $mapping = {
    cpqNicIfPhysAdapterRole => { oid => '.1.3.6.1.4.1.232.18.2.3.1.1.3', map => \%map_pnic_role },
};
my $mapping2 = {
    cpqNicIfPhysAdapterDuplexState  => { oid => '.1.3.6.1.4.1.232.18.2.3.1.1.11', map => \%map_nic_duplex },
    cpqNicIfPhysAdapterCondition => { oid => '.1.3.6.1.4.1.232.18.2.3.1.1.12', map => \%map_pnic_condition },
    cpqNicIfPhysAdapterState => { oid => '.1.3.6.1.4.1.232.18.2.3.1.1.13', map => \%map_nic_state },
    cpqNicIfPhysAdapterStatus => { oid => '.1.3.6.1.4.1.232.18.2.3.1.1.14', map => \%map_pnic_status },
};
my $oid_cpqNicIfPhysAdapterEntry = '.1.3.6.1.4.1.232.18.2.3.1.1';
my $oid_cpqNicIfPhysAdapterRole = '.1.3.6.1.4.1.232.18.2.3.1.1.3';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_cpqNicIfPhysAdapterEntry, start => $mapping->{cpqNicIfPhysAdapterDuplexState}->{oid}, end => $mapping->{cpqNicIfPhysAdapterStatus}->{oid} };
    push @{$options{request}}, { oid => $oid_cpqNicIfPhysAdapterRole };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking physical nics");
    $self->{components}->{pnic} = {name => 'physical nics', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'pnic'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqNicIfPhysAdapterEntry}})) {
        next if ($oid !~ /^$mapping2->{cpqNicIfPhysAdapterCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqNicIfPhysAdapterRole}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqNicIfPhysAdapterEntry}, instance => $instance);

        next if ($self->check_exclude(section => 'pnic', instance => $instance));
        $self->{components}->{pnic}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("physical nic '%s' [duplex: %s, role: %s, state: %s, status: %s] condition is %s.", 
                                    $instance, $result2->{cpqNicIfPhysAdapterDuplexState}, $result->{cpqNicIfPhysAdapterRole},
                                    $result2->{cpqNicIfPhysAdapterState}, $result2->{cpqNicIfPhysAdapterStatus},
                                    $result2->{cpqNicIfPhysAdapterCondition}));
        my $exit = $self->get_severity(section => 'pnic', value => $result2->{cpqNicIfPhysAdapterCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("physical nic '%s' is %s", 
                                            $instance, $result2->{cpqNicIfPhysAdapterCondition}));
        }
    }
}

1;