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

package network::extreme::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (
    1 => 'notPresent', 
    2 => 'presentOK', 
    3 => 'presentNotOK', 
    4 => 'presentPowerOff'
);

my $mapping = {
    extremePowerSupplyStatus => { oid => '.1.3.6.1.4.1.1916.1.1.1.27.1.2', map => \%map_psu_status },
    extremePowerSupplyFan1Speed => { oid => '.1.3.6.1.4.1.1916.1.1.1.27.1.6' },
    extremePowerSupplyFan2Speed => { oid => '.1.3.6.1.4.1.1916.1.1.1.27.1.7' },
    extremePowerSupplyInputPowerUsage => { oid => '.1.3.6.1.4.1.1916.1.1.1.27.1.9' },
    extremePowerSupplyInputPowerUsageUnitMultiplier => { oid => '.1.3.6.1.4.1.1916.1.1.1.27.1.11' },
};
my $oid_extremePowerSupplyEntry = '.1.3.6.1.4.1.1916.1.1.1.27.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_extremePowerSupplyEntry, start => $mapping->{extremePowerSupplyStatus}->{oid} };
}

sub check_fan_speed {
    my ($self, %options) = @_;
    
    if (!defined($options{value}) || $options{value} < 0) {
        return ;
    }
    
    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu.fan', instance => $options{instance}, value => $options{value});            
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Power supply fan '%s' is '%s' rpm", $options{instance}, $options{value}));
    }
    $self->{output}->perfdata_add(label => 'psu_fan_' . $options{instance}, unit => 'rpm', 
                                  value => $options{value},
                                  warning => $warn,
                                  critical => $crit, min => 0
                                  );
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'power supplies', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_extremePowerSupplyEntry}})) {
        next if ($oid !~ /^$mapping->{extremePowerSupplyStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_extremePowerSupplyEntry}, instance => $instance);
        
        next if ($self->check_exclude(section => 'psu', instance => $instance));
        if ($result->{extremePowerSupplyStatus} =~ /notPresent/i) {
            $self->absent_problem(section => 'psu', instance => $instance);
            next;
        }

        my $power = $result->{extremePowerSupplyInputPowerUsage} * (10 ** $result->{extremePowerSupplyInputPowerUsageUnitMultiplier});
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is '%s' [instance = %s, fan1speed = %s, fan2speed = %s, power = %s]",
                                                        $instance, $result->{extremePowerSupplyStatus}, $instance, 
                                                        $result->{extremePowerSupplyFan1Speed}, $result->{extremePowerSupplyFan2Speed}, $power
                                                        ));
        my $exit = $self->get_severity(section => 'psu', value => $result->{extremePowerSupplyStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is '%s'", $instance, $result->{extremePowerSupplyStatus}));
        }
        
        check_fan_speed($self, value => $result->{extremePowerSupplyFan1Speed}, instance => $instance . '.1');
        check_fan_speed($self, value => $result->{extremePowerSupplyFan2Speed}, instance => $instance . '.2');
        
        if ($power != 0) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu', instance => 'psu', value => $power);            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Power supply '%s' power is '%s' W", $instance, $power));
            }
            $self->{output}->perfdata_add(label => 'psu_power_' . $instance, unit => 'W', 
                                          value => $power,
                                          warning => $warn,
                                          critical => $crit, min => 0
                                          );
        }
    }
}

1;