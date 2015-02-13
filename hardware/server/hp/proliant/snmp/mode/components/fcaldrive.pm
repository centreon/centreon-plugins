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

package hardware::server::hp::proliant::snmp::mode::components::fcaldrive;

use strict;
use warnings;

my %map_fcaldrive_status = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'unconfigured',
    5 => 'recovering',
    6 => 'readyForRebuild',
    7 => 'rebuilding',
    8 => 'wrongDrive',
    9 => 'badConnect',
    10 => 'overheating',
    11 => 'shutdown',
    12 => 'expanding',
    13 => 'notAvailable',
    14 => 'queuedForExpansion',
    15 => 'hardError',
);

my %map_fcaldrive_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

my %map_faulttol = (
    1 => 'other',
    2 => 'none',
    3 => 'mirroring',
    4 => 'dataGuard',
    5 => 'distribDataGuard',
    7 => 'advancedDataGuard',
);

# In 'CPQFCA-MIB.mib'
my $mapping = {
    cpqFcaLogDrvFaultTol => { oid => '.1.3.6.1.4.1.232.16.2.3.1.1.3', map => \%map_faulttol },
    cpqFcaLogDrvStatus => { oid => '.1.3.6.1.4.1.232.16.2.3.1.1.4', map => \%map_fcaldrive_status },
};
my $mapping2 = {
    cpqFcaLogDrvCondition => { oid => '.1.3.6.1.4.1.232.16.2.3.1.1.11', map => \%map_fcaldrive_condition },
};
my $oid_cpqFcaLogDrvEntry = '.1.3.6.1.4.1.232.16.2.3.1.1';
my $oid_cpqFcaLogDrvCondition = '.1.3.6.1.4.1.232.16.2.3.1.1.11';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_cpqFcaLogDrvEntry, start => $mapping->{cpqFcaLogDrvFaultTol}->{oid}, end => $mapping->{cpqFcaLogDrvStatus}->{oid} };
    push @{$options{request}}, { oid => $oid_cpqFcaLogDrvCondition };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fca logical drives");
    $self->{components}->{fcaldrive} = {name => 'fca logical drives', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fcaldrive'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqFcaLogDrvCondition}})) {
        next if ($oid !~ /^$mapping2->{cpqFcaLogDrvCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqFcaLogDrvEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqFcaLogDrvCondition}, instance => $instance);

        next if ($self->check_exclude(section => 'fcaldrive', instance => $instance));
        $self->{components}->{fcaldrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fca logical drive '%s' [fault tolerance: %s, condition: %s] status is %s.", 
                                    $instance,
                                    $result->{cpqFcaLogDrvFaultTol}, 
                                    $result2->{cpqFcaLogDrvCondition},
                                    $result->{cpqFcaLogDrvStatus}));
        my $exit = $self->get_severity(section => 'fcaldrive', value => $result->{cpqFcaLogDrvStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("fca logical drive '%s' is %s", 
                                                $instance, $result->{cpqFcaLogDrvStatus}));
        }
    }
}

1;