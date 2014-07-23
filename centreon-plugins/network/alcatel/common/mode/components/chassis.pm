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

package network::alcatel::common::mode::components::chassis;

use strict;
use warnings;
use network::alcatel::common::mode::components::resources qw(%physical_class %phys_oper_status %phys_admin_status %oids);

my @admin_conditions = (
    ['^(reset|takeover|resetWithFabric|takeoverWithFabrc)$', 'WARNING'],
    ['^(powerOff)$', 'CRITICAL'],
    ['^(?!(powerOn|standby)$)', 'UNKNOWN'],
);

my @oper_conditions = (
    ['^(testing)$', 'WARNING'],
    ['^(unpowered|down|notpresent)$', 'CRITICAL'],
    ['^(?!(up|secondary|master|idle)$)', 'UNKNOWN'],
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking chassis");
    $self->{components}->{chassis} = {name => 'chassis', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'chassis'));
    
    my @instances = ();
    foreach my $key (keys %{$self->{results}->{$oids{entPhysicalClass}}}) {
        if ($self->{results}->{$oids{entPhysicalClass}}->{$key} == 3) {
            next if ($key !~ /^$oids{entPhysicalClass}\.(.*)$/);
            push @instances, $1;
        }
    }
    
    return if (scalar(@instances) == 0);
    
    foreach my $instance (@instances) {
        next if (!defined($self->{results}->{$oids{chasEntPhysAdminStatus}}->{$oids{chasEntPhysAdminStatus} . '.' . $instance}));
        
        my $descr = defined($self->{results}->{$oids{entPhysicalDescr}}->{$oids{entPhysicalDescr} . '.' . $instance}) ? 
                        $self->{results}->{$oids{entPhysicalDescr}}->{$oids{entPhysicalDescr} . '.' . $instance} : 'unknown';
        my $name  = defined($self->{results}->{$oids{entPhysicalName}}->{$oids{entPhysicalName} . '.' . $instance}) ? 
                        $self->{results}->{$oids{entPhysicalName}}->{$oids{entPhysicalName} . '.' . $instance} : 'unknown';
        my $admin_status = defined($self->{results}->{$oids{chasEntPhysAdminStatus}}->{$oids{chasEntPhysAdminStatus} . '.' . $instance}) ? 
                            $self->{results}->{$oids{chasEntPhysAdminStatus}}->{$oids{chasEntPhysAdminStatus} . '.' . $instance} : 1;
        my $oper_status = defined($self->{results}->{$oids{chasEntPhysOperStatus}}->{$oids{chasEntPhysOperStatus} . '.' . $instance}) ? 
                            $self->{results}->{$oids{chasEntPhysOperStatus}}->{$oids{chasEntPhysOperStatus} . '.' . $instance} : 4;
        my $power = defined($self->{results}->{$oids{chasEntPhysPower}}->{$oids{chasEntPhysPower} . '.' . $instance}) ? 
                            $self->{results}->{$oids{chasEntPhysPower}}->{$oids{chasEntPhysPower} . '.' . $instance} : -1;
        
        next if ($self->check_exclude(section => 'chassis', instance => $instance));
        $self->{components}->{chassis}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("chassis '%s/%s' [instance: %s, admin status: %s] operationnal status is %s.",
                                                        $name, $descr, $instance, 
                                                        $phys_admin_status{$admin_status}, $phys_oper_status{$oper_status})
                                    );
        
        my $go_forward = 1;
        foreach (@admin_conditions) {
            if ($phys_admin_status{$admin_status} =~ /$$_[0]/i) {
                $self->{output}->output_add(severity =>  $$_[1],
                                            short_msg => sprintf("chassis '%s/%s/%s' admin status is %s",
                                                        $name, $descr, $instance, $phys_admin_status{$admin_status}));
                $go_forward = 0;
                last;
            }
        }
        
        if ($power > 0) {
            $self->{output}->perfdata_add(label => "power_" . $instance, unit => 'W',
                                          value => $power,
                                          min => 0);
        }

        next if ($go_forward == 0);
        
        foreach (@oper_conditions) {
            if ($phys_oper_status{$oper_status} =~ /$$_[0]/i) {
                $self->{output}->output_add(severity =>  $$_[1],
                                            short_msg => sprintf("chassis '%s/%s/%s' oeprationnal status is %s",
                                                        $name, $descr, $instance, $phys_oper_status{$oper_status}));
                last;
            }
        }
    }
    
    # Check board temp
    $self->{snmp}->load(oids => [$oids{chasHardwareBoardTemp}, $oids{chasTempThreshold}, $oids{chasDangerTempThreshold}], 
                        instances => [@instances]);
    my $result = $self->{snmp}->get_leef();
    foreach my $instance (@instances) {
        my $value = defined($result->{$oids{chasHardwareBoardTemp} . '.' . $instance}) ? 
                            $result->{$oids{chasHardwareBoardTemp} . '.' . $instance} : undef;
        my $warn = defined($result->{$oids{chasTempThreshold} . '.' . $instance}) ? 
                            $result->{$oids{chasTempThreshold} . '.' . $instance} : undef;
        my $crit = defined($result->{$oids{chasDangerTempThreshold} . '.' . $instance}) ? 
                            $result->{$oids{chasDangerTempThreshold} . '.' . $instance} : undef;
        
        next if (!defined($value));
        
        $self->{perfdata}->threshold_validate(label => 'warning_' . $instance, value => $warn);
        $self->{perfdata}->threshold_validate(label => 'critical_' . $instance, value => $crit);
        
        my $exit = $self->{perfdata}->threshold_check(value => $value, threshold => [ { label => 'critical_' . $instance, 'exit_litteral' => 'critical' }, { label => 'warning_' . $instance, exit_litteral => 'warning' } ]);
        $self->{output}->output_add(long_msg => sprintf("Temperature board '%s' value is %s C.",
                                    $instance, $value));
         if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature board '%s' value is %s C", $instance, $value));
        }

        $self->{output}->perfdata_add(label => 'temp_board_' . $instance, unit => 'C',
                                      value => $value,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_' . $instance),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_' . $instance),
                                      );
    }
}

1;