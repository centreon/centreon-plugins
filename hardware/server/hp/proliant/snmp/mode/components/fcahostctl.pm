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

package hardware::server::hp::proliant::snmp::mode::components::fcahostctl;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_fcahostctl_status = (
    1 => 'other',
    2 => 'ok',
    3 => 'failed',
    4 => 'shutdown',
    5 => 'loopDegraded',
    6 => 'loopFailed',
    7 => 'notConnected',
);

my %map_fcahostctl_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

my %model_map = (
    1 => 'other',
    2 => 'fchc-p',
    3 => 'fchc-e',
    4 => 'fchc64',
    5 => 'sa-sam',
    6 => 'fca-2101',
    7 => 'sw64-33',
    8 => 'fca-221x',
    9 => 'dpfcmc',
    10 => 'fca-2404',
    11 => 'fca-2214',
    12 => 'a7298a',
    13 => 'fca-2214dc',
    14 => 'a6826a',
    15 => 'fcmcG3',
    16 => 'fcmcG4',
    17 => 'ab46xa',
    18 => 'fc-generic',
    19 => 'fca-1143',
    20 => 'fca-1243',
    21 => 'fca-2143',
    22 => 'fca-2243',
    23 => 'fca-1050',
    24 => 'fca-lpe1105',
    25 => 'fca-qmh2462',
    26 => 'fca-1142sr',
    27 => 'fca-1242sr',
    28 => 'fca-2142sr',
    29 => 'fca-2242sr',
    30 => 'fcmc20pe',
    31 => 'fca-81q',
    32 => 'fca-82q',
    33 => 'fca-qmh2562',
    34 => 'fca-81e',
    35 => 'fca-82e',
    36 => 'fca-1205',
);

# In 'CPQFCA-MIB.mib'
my $mapping = {
    cpqFcaHostCntlrSlot => { oid => '.1.3.6.1.4.1.232.16.2.7.1.1.2' },
    cpqFcaHostCntlrModel => { oid => '.1.3.6.1.4.1.232.16.2.7.1.1.3', map => \%model_map },
    cpqFcaHostCntlrStatus => { oid => '.1.3.6.1.4.1.232.16.2.7.1.1.4', map => \%map_fcahostctl_status },
    cpqFcaHostCntlrCondition => { oid => '.1.3.6.1.4.1.232.16.2.7.1.1.5', map => \%map_fcahostctl_condition },
};
my $oid_cpqFcaHostCntlrEntry = '.1.3.6.1.4.1.232.16.2.7.1.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_cpqFcaHostCntlrEntry, start => $mapping->{cpqFcaHostCntlrSlot}->{oid}, end => $mapping->{cpqFcaHostCntlrCondition}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fca host controller");
    $self->{components}->{fcahostctl} = {name => 'fca host controllers', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fcahostctl'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqFcaHostCntlrEntry}})) {
        next if ($oid !~ /^$mapping->{cpqFcaHostCntlrCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqFcaHostCntlrEntry}, instance => $instance);

        next if ($self->check_exclude(section => 'fcahostctl', instance => $instance));
        $self->{components}->{fcahostctl}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("fca host controller '%s' [slot: %s, model: %s, status: %s] condition is %s.", 
                                    $instance, $result->{cpqFcaHostCntlrSlot}, $result->{cpqFcaHostCntlrModel}, $result->{cpqFcaHostCntlrStatus},
                                    $result->{cpqFcaHostCntlrCondition}));
        my $exit = $self->get_severity(section => 'fcahostctl', value => $result->{cpqFcaHostCntlrCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("fca host controller '%s' is %s", 
                                            $instance, $result->{cpqFcaHostCntlrCondition}));
        }
    }
}

1;