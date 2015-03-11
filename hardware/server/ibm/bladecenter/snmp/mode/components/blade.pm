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

package hardware::server::ibm::bladecenter::snmp::mode::components::blade;

use strict;
use warnings;

my %map_blade_health_state = (
    0 => 'unknown',
    1 => 'good',
    2 => 'warning',
    3 => 'critical',
    4 => 'kernelMode',
    5 => 'discovering',
    6 => 'commError',
    7 => 'noPower',
    8 => 'flashing',
    9 => 'initFailure',
    10 => 'insufficientPower',
    11 => 'powerDenied',
);
my %map_blade_exists = (
    0 => 'false',
    1 => 'true',
);
my %map_blade_power_state = (
    0 => 'off',
    1 => 'on',
    3 => 'standby',
    4 => 'hibernate',
);

# In MIB 'CPQSTDEQ-MIB.mib'
my $mapping = {
    bladeId => { oid => '.1.3.6.1.4.1.2.3.51.2.22.1.5.1.1.2' },
    bladeExists => { oid => '.1.3.6.1.4.1.2.3.51.2.22.1.5.1.1.3', map => \%map_blade_exists  },
    bladePowerState => { oid => '.1.3.6.1.4.1.2.3.51.2.22.1.5.1.1.4', map => \%map_blade_power_state },
    bladeHealthState => { oid => '.1.3.6.1.4.1.2.3.51.2.22.1.5.1.1.5', map => \%map_blade_health_state },
    bladeName => { oid => '.1.3.6.1.4.1.2.3.51.2.22.1.5.1.1.6' },
};
my $oid_bladeSystemStatusEntry = '.1.3.6.1.4.1.2.3.51.2.22.1.5.1.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_bladeSystemStatusEntry, start => $mapping->{bladeId}->{oid}, end => $mapping->{bladeName}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking blades");
    $self->{components}->{blade} = {name => 'blades', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'blade'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_bladeSystemStatusEntry}})) {
        next if ($oid !~ /^$mapping->{bladeExists}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_bladeSystemStatusEntry}, instance => $instance);
        
        next if ($self->check_exclude(section => 'blade', instance => $result->{bladeId}));
         next if ($result->{bladeExists} =~ /No/i && 
                 $self->absent_problem(section => 'blade', instance => $result->{bladeId}));
        $self->{components}->{blade}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Blade '%s' state is %s [power state: %s]", 
                                    $result->{bladeId}, $result->{bladeHealthState}, $result->{bladePowerState}));
        my $exit = $self->get_severity(section => 'blade', value => $result->{bladeHealthState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power module '%s' state is %s", 
                                            $result->{bladeId}, $result->{bladeHealthState}));
        }
    }
}

1;