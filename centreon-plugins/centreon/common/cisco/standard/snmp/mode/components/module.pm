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

package centreon::common::cisco::standard::snmp::mode::components::module;

use strict;
use warnings;

my %map_module_state = (
    1 => 'unknown',
    2 => 'ok',
    3 => 'disabled',
    4 => 'okButDiagFailed',
    5 => 'boot',
    6 => 'selfTest',
    7 => 'failed',
    8 => 'missing',
    9 => 'mismatchWithParent',
    10 => 'mismatchConfig',
    11 => 'diagFailed',
    12 => 'dormant',
    13 => 'outOfServiceAdmin',
    14 => 'outOfServiceEnvTemp',
    15 => 'poweredDown',
    16 => 'poweredUp',
    17 => 'powerDenied',
    18 => 'powerCycled',
    19 => 'okButPowerOverWarning',
    20 => 'okButPowerOverCritical',
    21 => 'syncInProgress',
    22 => 'upgrading',
    23 => 'okButAuthFailed',
    24 => 'mdr',
    25 => 'fwMismatchFound',
    26 => 'fwDownloadSuccess',
    27 => 'fwDownloadFailure',
);

# In MIB 'CISCO-ENTITY-SENSOR-MIB'
my $mapping = {
    cefcModuleOperStatus => { oid => '.1.3.6.1.4.1.9.9.117.1.2.1.1.2', map => \%map_module_state },
};
my $oid_cefcModuleOperStatus = '.1.3.6.1.4.1.9.9.117.1.2.1.1.2';
my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_cefcModuleOperStatus };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking modules");
    $self->{components}->{module} = {name => 'modules', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'module'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cefcModuleOperStatus}})) {
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cefcModuleOperStatus}, instance => $instance);
        my $module_descr = $self->{results}->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        
        next if ($self->check_exclude(section => 'module', instance => $instance));
        
        $self->{components}->{module}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Module '%s' status is %s [instance: %s]",
                                    $module_descr, $result->{cefcModuleOperStatus}, $instance));
        my $exit = $self->get_severity(section => 'module', value => $result->{cefcModuleOperStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Module '%s' status is %s", $module_descr, $result->{cefcModuleOperStatus}));
        }
    }
}

1;