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

package hardware::server::ibm::bladecenter::snmp::mode::components::blower;

use strict;
use warnings;

my %map_blower_state = (
    0 => 'unknown', 
    1 => 'good', 
    2 => 'warning', 
    3 => 'bad',
);
my %map_controller_state = (
    0 => 'operational',
    1 => 'flashing',
    2 => 'notPresent',
    3 => 'communicationError',
    255 => 'unknown',
);

# In MIB 'mmblade.mib'
my $oid_blowers = '.1.3.6.1.4.1.2.3.51.2.2.3';
my $entry_blower_state = '10';
my $entry_blower_speed = '1';
my $entry_controller_state = '30';
my $count = 4;

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_blowers };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking blowers");
    $self->{components}->{blower} = {name => 'blowers', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'blower'));

    for (my $i = 0; $i < $count; $i++) {
        my $instance = $i + 1;
        next if (!defined($self->{results}->{$oid_blowers}->{$oid_blowers . '.' . ($entry_blower_state + $i) . '.0'}));
        my $blower_state = $map_blower_state{$self->{results}->{$oid_blowers}->{$oid_blowers . '.' . ($entry_blower_state + $i) . '.0'}};
        my $blower_speed = defined($self->{results}->{$oid_blowers}->{$oid_blowers . '.' . ($entry_blower_speed + $i) . '.0'}) ? $self->{results}->{$oid_blowers}->{$oid_blowers . '.' . ($entry_blower_speed + $i) . '.0'} : 'unknown';
        my $ctrl_state = defined($self->{results}->{$oid_blowers}->{$oid_blowers . '.' . ($entry_controller_state + $i) . '.0'}) ? $map_controller_state{$self->{results}->{$oid_blowers}->{$oid_blowers . '.' . ($entry_controller_state + $i) . '.0'}} : undef;
    
        next if ($self->check_exclude(section => 'blower', instance => $instance));
        next if ($blower_speed =~ /No Blower/i && 
                 $self->absent_problem(section => 'blower', instance => $instance));
        $self->{components}->{blower}->{total}++;

        if ($blower_speed =~ /^(\d+)%/) {
            $blower_speed = $1;
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'blower', instance => $instance, value => $blower_speed);
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Blower speed '%s' is %s %%", $instance, $blower_speed));
            }
            $self->{output}->perfdata_add(label => "blower_speed_" . $instance, unit => '%',
                                          value => $blower_speed,
                                          warning => $warn,
                                          critical => $crit,
                                          min => 0, max => 100);
        }
        
        $self->{output}->output_add(long_msg => sprintf("Blower '%s' state is %s (%d %%).", 
                                    $instance, $blower_state, $blower_speed));
        my $exit = $self->get_severity(section => 'blower', value => $blower_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Blower '%s' state is %s", 
                                            $instance, $blower_state));
        }
        
        next if ($self->check_exclude(section => 'blowerctrl', instance => $instance));
        next if ($ctrl_state =~ /notPresent/i && 
                 $self->absent_problem(section => 'blowerctrl', instance => $instance));
        $self->{output}->output_add(long_msg => sprintf("Blower controller '%s' state is %s.", 
                                    $instance, $ctrl_state));
        $exit = $self->get_severity(section => 'blowerctrl', value => $ctrl_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Blower controller '%s' state is %s", 
                                            $instance, $ctrl_state));
        }
    }
}

1;