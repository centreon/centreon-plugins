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

package hardware::server::hp::proliant::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);

my %map_present = (
    1 => 'other',
    2 => 'absent',
    3 => 'present',
);

my %map_redundant = (
    1 => 'other',
    2 => 'not redundant',
    3 => 'redundant',
);

my %map_psu_status = (
    1  => 'noError',
    2  => 'generalFailure',
    3  => 'bistFailure',
    4  => 'fanFailure',
    5  => 'tempFailure',
    6  => 'interlockOpen',
    7  => 'epromFailed',
    8  => 'vrefFailed',
    9  => 'dacFailed',
    10 => 'ramTestFailed',
    11 => 'voltageChannelFailed',
    12 => 'orringdiodeFailed',
    13 => 'brownOut',
    14 => 'giveupOnStartup',
    15 => 'nvramInvalid',
    16 => 'calibrationTableInvalid',
);

# In MIB 'CPQHLTH-MIB.mib'
my $mapping = {
    cpqHeFltTolPowerSupplyPresent => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.3', map => \%map_present },
    cpqHeFltTolPowerSupplyCondition => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.4', map => \%map_psu_condition },
    cpqHeFltTolPowerSupplyStatus => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.5', map => \%map_psu_status },
    cpqHeFltTolPowerSupplyMainVoltage => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.6' },
    cpqHeFltTolPowerSupplyCapacityUsed => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.7' },
    cpqHeFltTolPowerSupplyCapacityMaximum => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.8' },
    cpqHeFltTolPowerSupplyRedundant => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.9' },
};
my $mapping2 = {
    cpqHeFltTolPowerSupplyRedundantPartner => { oid => '.1.3.6.1.4.1.232.6.2.9.3.1.17' },
};
my $oid_cpqHeFltTolPowerSupplyEntry = '.1.3.6.1.4.1.232.6.2.9.3.1';
my $oid_cpqHeFltTolPowerSupplyRedundantPartner = '.1.3.6.1.4.1.232.6.2.9.3.1.17';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_cpqHeFltTolPowerSupplyEntry, start => $mapping->{cpqHeFltTolPowerSupplyPresent}->{oid}, end => $mapping->{cpqHeFltTolPowerSupplyRedundant}->{oid} };
    push @{$options{request}}, { oid => $oid_cpqHeFltTolPowerSupplyRedundantPartner };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'power supplies', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqHeFltTolPowerSupplyEntry}})) {
        next if ($oid !~ /^$mapping->{cpqHeFltTolPowerSupplyPresent}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqHeFltTolPowerSupplyEntry}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqHeFltTolPowerSupplyRedundantPartner}, instance => $instance);

        next if ($self->check_exclude(section => 'psu', instance => $instance));
        next if ($result->{cpqHeFltTolPowerSupplyPresent} !~ /present/i && 
                 $self->absent_problem(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("powersupply '%s' status is %s [redundance: %s, redundant partner: %s] (status %s).",
                                    $instance, $result->{cpqHeFltTolPowerSupplyCondition},
                                    $result->{cpqHeFltTolPowerSupplyRedundant}, 
                                    defined($result2->{cpqHeFltTolPowerSupplyRedundantPartner}) ? $result2->{cpqHeFltTolPowerSupplyRedundantPartner} : 'unknown',
                                    $result->{cpqHeFltTolPowerSupplyStatus}
                                    ));
        my $exit = $self->get_severity(section => 'psu', value => $result->{cpqHeFltTolPowerSupplyCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("powersupply '%s' status is %s",
                                           $instance, $result->{cpqHeFltTolPowerSupplyCondition}));
        }
        
        $self->{output}->perfdata_add(label => "psu_power_" . $instance, unit => 'W',
                                      value => $result->{cpqHeFltTolPowerSupplyCapacityUsed},
                                      critical => $result->{cpqHeFltTolPowerSupplyCapacityMaximum});
        $self->{output}->perfdata_add(label => "psu__voltage" . $instance, unit => 'V',
                                      value => $result->{cpqHeFltTolPowerSupplyMainVoltage});
    }
}

1;