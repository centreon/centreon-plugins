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

package hardware::server::hp::proliant::snmp::mode::components::daldrive;

use strict;
use warnings;

my %map_daldrive_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);
my %map_ldrive_status = (
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
    15 => 'multipathAccessDegraded',
    16 => 'erasing',
);
my %map_faulttol = (
    1 => 'other',
    2 => 'none',
    3 => 'mirroring',
    4 => 'dataGuard',
    5 => 'distribDataGuard',
    7 => 'advancedDataGuard',
    8 => 'raid50',
    9 => 'raid60',
);
# In 'CPQIDA-MIB.mib'
my $mapping = {
    cpqDaLogDrvFaultTol => { oid => '.1.3.6.1.4.1.232.3.2.3.1.1.3', map => \%map_faulttol },
    cpqDaLogDrvStatus => { oid => '.1.3.6.1.4.1.232.3.2.3.1.1.4', map => \%map_ldrive_status },
};
my $mapping2 = {
    cpqDaLogDrvCondition => { oid => '.1.3.6.1.4.1.232.3.2.3.1.1.11', map => \%map_daldrive_condition },
};
my $oid_cpqDaLogDrvEntry = '.1.3.6.1.4.1.232.3.2.3.1.1';
my $oid_cpqDaLogDrvCondition = '.1.3.6.1.4.1.232.3.2.3.1.1.11';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_cpqDaLogDrvEntry, start => $mapping->{cpqDaLogDrvFaultTol}->{oid}, end => $mapping->{cpqDaLogDrvStatus}->{oid} };
    push @{$options{request}}, { oid => $oid_cpqDaLogDrvCondition };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking da logical drives");
    $self->{components}->{daldrive} = {name => 'da logical drives', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'daldrive'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqDaLogDrvCondition}})) {
        next if ($oid !~ /^$mapping2->{cpqDaLogDrvCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqDaLogDrvEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqDaLogDrvCondition}, instance => $instance);

        next if ($self->check_exclude(section => 'daldrive', instance => $instance));
        $self->{components}->{daldrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("da logical drive '%s' [fault tolerance: %s, condition: %s] status is %s.", 
                                    $instance,
                                    $result->{cpqDaLogDrvFaultTol}, 
                                    $result2->{cpqDaLogDrvCondition},
                                    $result->{cpqDaLogDrvStatus}));
        my $exit = $self->get_severity(section => 'daldrive', value => $result->{cpqDaLogDrvStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("da logical drive '%s' is %s", 
                                                $instance, $result->{cpqDaLogDrvStatus}));
        }
    }
}

1;