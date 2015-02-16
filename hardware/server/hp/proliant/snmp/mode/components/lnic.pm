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

package hardware::server::hp::proliant::snmp::mode::components::lnic;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_lnic_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
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

# In MIB 'CPQNIC-MIB.mib'
my $mapping = {
    cpqNicIfLogMapDescription => { oid => '.1.3.6.1.4.1.232.18.2.2.1.1.3' },
};
my $mapping2 = {
    cpqNicIfLogMapAdapterCount => { oid => '.1.3.6.1.4.1.232.18.2.2.1.1.5' },
};
my $mapping3 = {
    cpqNicIfLogMapCondition  => { oid => '.1.3.6.1.4.1.232.18.2.2.1.1.10', map => \%map_lnic_condition },
    cpqNicIfLogMapStatus => { oid => '.1.3.6.1.4.1.232.18.2.2.1.1.11', map => \%map_lnic_status },
};
my $oid_cpqNicIfLogMapEntry = '.1.3.6.1.4.1.232.18.2.2.1.1';
my $oid_cpqNicIfLogMapDescription = '.1.3.6.1.4.1.232.18.2.2.1.1.3';
my $oid_cpqNicIfLogMapAdapterCount = '.1.3.6.1.4.1.232.18.2.2.1.1.5';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_cpqNicIfLogMapEntry, start => $mapping->{cpqNicIfLogMapCondition}->{oid}, end => $mapping->{cpqNicIfLogMapStatus}->{oid} };
    push @{$options{request}}, { oid => $oid_cpqNicIfLogMapDescription };
    push @{$options{request}}, { oid => $oid_cpqNicIfLogMapAdapterCount };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking logical nics");
    $self->{components}->{lnic} = {name => 'logical nics', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'lnic'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqNicIfLogMapEntry}})) {
        next if ($oid !~ /^$mapping3->{cpqNicIfLogMapCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqNicIfLogMapDescription}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqNicIfLogMapAdapterCount}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$oid_cpqNicIfLogMapEntry}, instance => $instance);

        next if ($self->check_exclude(section => 'lnic', instance => $instance));
        $self->{components}->{lnic}->{total}++;

        $self->{output}->output_add(long_msg => printf("logical nic '%s' [adapter count: %s, description: %s, status: %s] condition is %s.", 
                                    $instance, $result2->{cpqNicIfLogMapAdapterCount}, centreon::plugins::misc::trim($result->{cpqNicIfLogMapDescription}),
                                    $result3->{cpqNicIfLogMapStatus},
                                    $result3->{cpqNicIfLogMapCondition}));
        my $exit = $self->get_severity(section => 'lnic', value => $result3->{cpqNicIfLogMapCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("logical nic '%s' is %s (%s)", 
                                            $instance, $result3->{cpqNicIfLogMapCondition}));
        }
    }
}

1;