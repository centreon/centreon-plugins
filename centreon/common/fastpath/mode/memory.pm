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
# Authors : Kevin Duret <kduret@merethis.com>
#
####################################################################################

package centreon::common::fastpath::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_agentSwitchCpuProcessMemFree = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.1.1.4.1.0'; # in KB
    my $oid_agentSwitchCpuProcessMemAvailable = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.1.1.4.2.0'; # in KB

	my $result = $self->{snmp}->get_leef(oids => [$oid_agentSwitchCpuProcessMemFree,
												  $oid_agentSwitchCpuProcessMemAvailable],
                                         nothing_quit => 1);
   
	my $memory_free = $result->{$oid_agentSwitchCpuProcessMemFree} * 1024;
	my $memory_available = $result->{$oid_agentSwitchCpuProcessMemAvailable} * 1024;
	my $memory_used = $memory_available - $memory_free;
	my $prct_used = ($memory_used / $memory_available) * 100;
	my $prct_free = ($memory_free / $memory_available) * 100;

	my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

	my ($memory_used_value, $memory_used_unit) = $self->{perfdata}->change_bytes(value => $memory_used);
	my ($memory_available_value, $memory_available_unit) = $self->{perfdata}->change_bytes(value => $memory_available);
	my ($memory_free_value, $memory_free_unit) = $self->{perfdata}->change_bytes(value => $memory_free);

	$self->{output}->output_add(severity => $exit,
    							short_msg => sprintf("Memory used: %s (%.2f%%), Size: %s, Free: %s (%.2f%%)",
                                            $memory_used_value . " " . $memory_used_unit, $prct_used,
                                            $memory_available_value . " " . $memory_available_unit,
                                            $memory_free_value . " " . $memory_free_unit, $prct_free));
	
	$self->{output}->perfdata_add(label => "used",
                                  value => $memory_used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $memory_available, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $memory_available, cast_int => 1),
                                  min => 0, max => $memory_available);

    $self->{output}->display();
    $self->{output}->exit();
    
}

1;

__END__

=head1 MODE

Check memory usage (FASTPATH-SWITCHING-MIB).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
    
