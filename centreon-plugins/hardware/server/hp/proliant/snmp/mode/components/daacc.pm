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

package hardware::server::hp::proliant::snmp::mode::components::daacc;

use strict;
use warnings;

my %map_daacc_status = (
    1 => 'other',
    2 => 'invalid',
    3 => 'enabled',
    4 => 'tmpDisabled',
    5 => 'permDisabled',
);
my %map_daacc_condition = (
    1 => 'other', 
    2 => 'ok', 
    3 => 'degraded', 
    4 => 'failed',
);
my %map_daaccbattery_condition = (
    1 => 'other', 
    2 => 'ok',
    3 => 'recharging', 
    4 => 'failed',
    5 => 'degraded',
    6 => 'not present',
);

# In 'CPQIDA-MIB.mib'
my $mapping = {
    cpqDaAccelStatus => { oid => '.1.3.6.1.4.1.232.3.2.2.2.1.2', map => \%map_daacc_status },
};
my $mapping2 = {
    cpqDaAccelBattery => { oid => '.1.3.6.1.4.1.232.3.2.2.2.1.6', map => \%map_daaccbattery_condition },
};
my $mapping3 = {
    cpqDaAccelCondition => { oid => '.1.3.6.1.4.1.232.3.2.2.2.1.9', map => \%map_daacc_condition },
};
my $oid_cpqDaAccelStatus = '.1.3.6.1.4.1.232.3.2.2.2.1.2';
my $oid_cpqDaAccelBattery = '.1.3.6.1.4.1.232.3.2.2.2.1.6';
my $oid_cpqDaAccelCondition = '.1.3.6.1.4.1.232.3.2.2.2.1.9';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_cpqDaAccelStatus };
    push @{$options{request}}, { oid => $oid_cpqDaAccelBattery };
    push @{$options{request}}, { oid => $oid_cpqDaAccelCondition };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking da accelerator boards");
    $self->{components}->{daacc} = {name => 'da accelerator boards', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'daacc'));
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpqDaAccelCondition}})) {
        next if ($oid !~ /^$mapping3->{cpqDaAccelCondition}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpqDaAccelStatus}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_cpqDaAccelBattery}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$oid_cpqDaAccelCondition}, instance => $instance);

        next if ($self->check_exclude(section => 'daacc', instance => $instance));
        $self->{components}->{daacc}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("da controller accelerator '%s' [status: %s, battery status: %s] condition is %s.", 
                                    $instance, $result->{cpqDaAccelStatus}, $result2->{cpqDaAccelBattery},
                                    $result3->{cpqDaAccelCondition}));
        my $exit = $self->get_severity(section => 'daacc', value => $result3->{cpqDaAccelCondition});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("da controller accelerator '%s' is %s", 
                                            $instance, $result3->{cpqDaAccelCondition}));
        }
        $exit = $self->get_severity(section => 'daaccbattery', value => $result2->{cpqDaAccelBattery});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("da controller accelerator '%s' battery is %s", 
                                            $instance, $result2->{cpqDaAccelBattery}));
        }
    }
}

1;