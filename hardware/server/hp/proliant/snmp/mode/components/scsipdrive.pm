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

package hardware::server::hp::proliant::snmp::mode::components::scsipdrive;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_pdrive_status = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'notConfigured',
    5 => 'badCable',
    6 => 'missingWasOk',
    7 => 'missingWasFailed',
    8 => 'predictiveFailure',
    9 => 'missingWasPredictiveFailure',
    10 => 'offline',
    11 => 'missingWasOffline',
    12 => 'hardError',
);

my %map_pdrive_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

# In 'CPQSCSI-MIB.mib'

my $mapping = {
    cpqScsiPhyDrvStatus => { oid => '.1.3.6.1.4.1.232.5.2.4.1.1.9', map => \%map_pdrive_status },
};
my $mapping2 = {
    cpqScsiPhyDrvCondition => { oid => '.1.3.6.1.4.1.232.5.2.4.1.1.26', map => \%map_pdrive_condition },    
};
my $oid_cpqScsiPhyDrvCondition = '.1.3.6.1.4.1.232.5.2.4.1.1.26';
my $oid_cpqScsiPhyDrvStatus = '.1.3.6.1.4.1.232.5.2.4.1.1.9';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_cpqScsiPhyDrvStatus };
    push @{$options{request}}, { oid => $oid_cpqScsiPhyDrvCondition };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking scsi physical drives");
    $self->{components}->{scsipdrive} = {name => 'scsi physical drives', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'scsipdrive'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqScsiPhyDrvCondition}})) {
        next if ($oid !~ /^$mapping->{cpqScsiPhyDrvCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqScsiPhyDrvStatus}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqScsiPhyDrvCondition}, instance => $instance);
        
        next if ($self->check_exclude(section => 'scsipdrive', instance => $instance));
        $self->{components}->{scsipdrive}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("scsi physical drive '%s' [status: %s] condition is %s.", 
                                    $instance,
                                    $result->{cpqScsiPhyDrvStatus},
                                    $result2->{cpqScsiPhyDrvCondition}));
        my $exit = $self->get_severity(section => 'scsipdrive', value => $result2->{cpqScsiPhyDrvCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("scsi physical drive '%s' is %s", 
                                                $instance, $result2->{cpqScsiPhyDrvCondition}));
        }
    }
}

1;