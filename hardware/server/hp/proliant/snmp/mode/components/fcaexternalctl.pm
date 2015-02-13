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

package hardware::server::hp::proliant::snmp::mode::components::fcaexternalctl;

use strict;
use warnings;

my %map_fcaexternalctl_status = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'offline',
    5 => 'redundantPathOffline',
    6 => 'notConnected',
);

my %map_fcaexternalctl_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

my %model_map = (
    1 => 'other',
    2 => 'fibreArray',
    3 => 'msa1000',
    4 => 'smartArrayClusterStorage',
    5 => 'hsg80',
    6 => 'hsv110',
    7 => 'msa500G2',
    8 => 'msa20',
    9 => 'msa1510i',
);

my %map_role = (
    1 => 'other',
    2 => 'notDuplexed',
    3 => 'active',
    4 => 'backup',
);

# In 'CPQFCA-MIB.mib'    
my $mapping = {
    cpqFcaCntlrModel => { oid => '.1.3.6.1.4.1.232.16.2.2.1.1.3', map => \%model_map },
    cpqFcaCntlrStatus => { oid => '.1.3.6.1.4.1.232.16.2.2.1.1.5', map => \%map_fcaexternalctl_status },
    cpqFcaCntlrCondition => { oid => '.1.3.6.1.4.1.232.16.2.2.1.1.6', map => \%map_fcaexternalctl_condition },
};
my $mapping2 = {
    cpqFcaCntlrCurrentRole => { oid => '.1.3.6.1.4.1.232.16.2.2.1.1.10', map => \%map_role },
};
my $oid_cpqFcaCntlrEntry = '.1.3.6.1.4.1.232.16.2.2.1.1';
my $oid_cpqFcaCntlrCurrentRole = '.1.3.6.1.4.1.232.16.2.2.1.1.10';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_cpqFcaCntlrEntry, start => $mapping->{cpqFcaCntlrModel}->{oid}, end => $mapping->{cpqFcaCntlrCondition}->{oid} };
    push @{$options{request}}, { oid => $oid_cpqFcaCntlrCurrentRole };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fca external controller");
    $self->{components}->{fcaexternalctl} = {name => 'fca external controllers', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fcaexternalctl'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqFcaCntlrEntry}})) {
        next if ($oid !~ /^$mapping->{cpqFcaCntlrCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqFcaCntlrEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqFcaCntlrCurrentRole}, instance => $instance);

        next if ($self->check_exclude(section => 'fcaexternalctl', instance => $instance));
        $self->{components}->{fcaexternalctl}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fca external controller '%s' [model: %s, status: %s, role: %s] condition is %s.", 
                                    $instance,
                                    $result->{cpqFcaCntlrModel}, $result->{cpqFcaCntlrStatus}, $result2->{cpqFcaCntlrCurrentRole},
                                    $result->{cpqFcaCntlrCondition}));
        my $exit = $self->get_severity(section => 'fcaexternalctl', value => $result->{cpqFcaCntlrCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("fca external controller '%s' is %s", 
                                            $instance, $result->{cpqFcaCntlrCondition}));
        }
    }
}

1;