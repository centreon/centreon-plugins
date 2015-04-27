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

package centreon::common::fastpath::mode::cpu;

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
                                  "warning:s"               => { name => 'warning', default => '' },
                                  "critical:s"              => { name => 'critical', default => '' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    ($self->{warn5s}, $self->{warn1m}, $self->{warn5m}) = split /,/, $self->{option_results}->{warning};
    ($self->{crit5s}, $self->{crit1m}, $self->{crit5m}) = split /,/, $self->{option_results}->{critical};
    
    if (($self->{perfdata}->threshold_validate(label => 'warn1s', value => $self->{warn5s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1sec) threshold '" . $self->{warn5s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn1m', value => $self->{warn1m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1min) threshold '" . $self->{warn1m} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn5m', value => $self->{warn5m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (5min) threshold '" . $self->{warn5m} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit1s', value => $self->{crit5s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1sec) threshold '" . $self->{crit5s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit1m', value => $self->{crit1m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1min) threshold '" . $self->{crit1m} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit5m', value => $self->{crit5m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (5min) threshold '" . $self->{crit5m} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_agentSwitchCpuProcessTotalUtilization1 = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.1.1.4.9.0';
   	my $oid_agentSwitchCpuProcessTotalUtilization2 = '.1.3.6.1.4.1.674.10895.5000.2.6132.1.1.1.1.4.4.0'; # oid for 6200 series
    $self->{result} = $self->{snmp}->get_leef(oids => [ $oid_agentSwitchCpuProcessTotalUtilization1, $oid_agentSwitchCpuProcessTotalUtilization2 ],
                                              nothing_quit => 1);
    
	my $cpu_usage;
	if ((defined($self->{result}->{$oid_agentSwitchCpuProcessTotalUtilization1})) && ($self->{result}->{$oid_agentSwitchCpuProcessTotalUtilization1} =~ /sec.*(sec|min).*(sec|min)/i)) {
		$cpu_usage = $self->{result}->{$oid_agentSwitchCpuProcessTotalUtilization1};
	} elsif ((defined($self->{result}->{$oid_agentSwitchCpuProcessTotalUtilization2})) && ($self->{result}->{$oid_agentSwitchCpuProcessTotalUtilization2} =~ /sec.*(sec|min).*(sec|min)/i)) {
		$cpu_usage = $self->{result}->{$oid_agentSwitchCpuProcessTotalUtilization2};
	} else {
		$self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf("Can't get CPU information."));
		$self->{output}->display();
    	$self->{output}->exit();
	}
	if ($cpu_usage =~ /^.*\(\s*(\S+)%\).*\(\s*(\S+)%\).*\(\s*(\S+)%\)/) {
		my $cpu5sec = $1;
		my $cpu1min = $2;
		my $cpu5min = $3;

		my $exit1 = $self->{perfdata}->threshold_check(value => $cpu5sec,
                               threshold => [ { label => 'crit5s', 'exit_litteral' => 'critical' }, { label => 'warn5s', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{perfdata}->threshold_check(value => $cpu1min,
                               threshold => [ { label => 'crit1m', 'exit_litteral' => 'critical' }, { label => 'warn1m', exit_litteral => 'warning' } ]);
        my $exit3 = $self->{perfdata}->threshold_check(value => $cpu5min,
                               threshold => [ { label => 'crit5m', 'exit_litteral' => 'critical' }, { label => 'warn5m', exit_litteral => 'warning' } ]);
        my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3 ]);

		$self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("CPU Usage: %.2f%% (5sec), %.2f%% (1min), %.2f%% (5min)",
                                                        $cpu5sec, $cpu1min, $cpu5min));

		$self->{output}->perfdata_add(label => "cpu_5s", unit => '%',
                                      value => $cpu5sec,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5s'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5s'),
                                      min => 0, max => 100);
        $self->{output}->perfdata_add(label => "cpu_1m", unit => '%',
                                      value => $cpu1min,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1m'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1m'),
                                      min => 0, max => 100);
        $self->{output}->perfdata_add(label => "cpu_5m", unit => '%',
                                      value => $cpu5min,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5m'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5m'),
                                      min => 0, max => 100);
	} else {
		$self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf("Can't parse CPU usage."));
	}

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check cpu usage (FASTPATH-SWITCHING-MIB).

=over 8

=item B<--warning>

Threshold warning in percent (5s,1min,5min).

=item B<--critical>

Threshold critical in percent (5s,1min,5min).

=back

=cut
