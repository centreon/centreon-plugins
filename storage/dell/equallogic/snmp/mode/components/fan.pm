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

package storage::dell::equallogic::snmp::mode::components::fan;

use strict;
use warnings;

my %map_fan_status = (
    0 => 'unknown', 
    1 => 'normal', 
    2 => 'warning', 
    3 => 'critical',
);

# In MIB 'eqlcontroller.mib'
my $mapping = {
    eqlMemberHealthDetailsFanName => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.2' },
    eqlMemberHealthDetailsFanValue => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.3' },
    eqlMemberHealthDetailsFanCurrentState => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.4', map => \%map_fan_status },
    eqlMemberHealthDetailsFanHighCriticalThreshold => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.5' },
    eqlMemberHealthDetailsFanHighWarningThreshold => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.6' },
    eqlMemberHealthDetailsFanLowCriticalThreshold => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.7' },
    eqlMemberHealthDetailsFanLowWarningThreshold => { oid => '.1.3.6.1.4.1.12740.2.1.7.1.8' },
};
my $oid_eqlMemberHealthDetailsFanEntry = '.1.3.6.1.4.1.12740.2.1.7.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_eqlMemberHealthDetailsFanEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_eqlMemberHealthDetailsFanEntry}})) {
        next if ($oid !~ /^$mapping->{eqlMemberHealthDetailsFanCurrentState}->{oid}\.(\d+\.\d+)\.(.*)$/);
        my ($member_instance, $instance) = ($1, $2);
        my $member_name = $self->get_member_name(instance => $member_instance);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_eqlMemberHealthDetailsFanEntry}, instance => $member_instance . '.' . $instance);

        next if ($self->check_exclude(section => 'fan', instance => $instance));
        $self->{components}->{fan}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Fan '%s/%s' status is %s [instance: %s].",
                                    $member_name, $result->{eqlMemberHealthDetailsFanName}, $result->{eqlMemberHealthDetailsFanCurrentState},
                                    $instance
                                    ));
        my $exit = $self->get_severity(section => 'fan', value => $result->{eqlMemberHealthDetailsFanCurrentState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Fan '%s/%s' status is %s",
                                                             $member_name, $result->{eqlMemberHealthDetailsFanName}, $result->{eqlMemberHealthDetailsFanCurrentState}));
        }
        
        if (defined($result->{eqlMemberHealthDetailsFanValue})) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{eqlMemberHealthDetailsFanValue});
            if ($checked == 0) {
                my $warn_th = $result->{eqlMemberHealthDetailsFanLowWarningThreshold} . ':' . $result->{eqlMemberHealthDetailsFanHighWarningThreshold};
                my $crit_th = $result->{eqlMemberHealthDetailsFanLowCriticalThreshold} . ':' . $result->{eqlMemberHealthDetailsFanHighCriticalThreshold};
                $self->{perfdata}->threshold_validate(label => 'warning-fan-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-fan-instance-' . $instance, value => $crit_th);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-fan-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-fan-instance-' . $instance);
            }
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Fan '%s/%s' speed is %s rpm", $member_name, $result->{eqlMemberHealthDetailsFanName}, $result->{eqlMemberHealthDetailsFanValue}));
            }
            $self->{output}->perfdata_add(label => "fan_" . $member_name . "_" . $instance, unit => 'rpm',
                                          value => $result->{eqlMemberHealthDetailsFanValue},
                                          warning => $warn,
                                          critical => $crit,
                                          min => 0);
        }
    }
}

1;