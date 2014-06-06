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
# Authors : Stephane Duret <sduret@merethis.com>
#
####################################################################################

package network::juniper::common::screenos::mode::cpu;

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
    
    ($self->{warn1s}, $self->{warn4s}, $self->{warn64s}) = split /,/, $self->{option_results}->{warning};
    ($self->{crit1s}, $self->{crit4s}, $self->{crit64s}) = split /,/, $self->{option_results}->{critical};
    
    if (($self->{perfdata}->threshold_validate(label => 'warn1min', value => $self->{warn1s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1min) threshold '" . $self->{warn1s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn5min', value => $self->{warn4s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (5min) threshold '" . $self->{warn4s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn15min', value => $self->{warn64s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (15min) threshold '" . $self->{warn64s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit1min', value => $self->{crit1s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1min) threshold '" . $self->{crit1s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit5min', value => $self->{crit4s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (5min) threshold '" . $self->{crit4s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit15min', value => $self->{crit64s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (15min) threshold '" . $self->{crit64s} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_nsResCpuLast1Min = '.1.3.6.1.4.1.3224.16.1.2.0';
    my $oid_nsResCpuLast5Min = '.1.3.6.1.4.1.3224.16.1.3.0';
    my $oid_nsResCpuLast15Min = '.1.3.6.1.4.1.3224.16.1.4.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_nsResCpuLast1Min, $oid_nsResCpuLast5Min,
                                                  $oid_nsResCpuLast15Min], nothing_quit => 1);
    
    my $cpu1min = $result->{$oid_nsResCpuLast1Min};
    my $cpu5min = $result->{$oid_nsResCpuLast5Min};
    my $cpu15min = $result->{$oid_nsResCpuLast15Min};
    
    my $exit1 = $self->{perfdata}->threshold_check(value => $cpu1min, 
                           threshold => [ { label => 'crit1min', 'exit_litteral' => 'critical' }, { label => 'warn1min', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $cpu5min, 
                           threshold => [ { label => 'crit5min', 'exit_litteral' => 'critical' }, { label => 'warn5min', exit_litteral => 'warning' } ]);
    my $exit3 = $self->{perfdata}->threshold_check(value => $cpu15min, 
                           threshold => [ { label => 'crit15min', 'exit_litteral' => 'critical' }, { label => 'warn15min', exit_litteral => 'warning' } ]);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3 ]);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("CPU Usage: %.2f%% (1min), %.2f%% (5min), %.2f%% (15min)",
                                      $cpu1min, $cpu5min, $cpu15min));
    
    $self->{output}->perfdata_add(label => "cpu_1min",
                                  value => $cpu1min,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1min'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1min'),
                                  min => 0, max => 100);
    $self->{output}->perfdata_add(label => "cpu_5min",
                                  value => $cpu5min,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5min'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5min'),
                                  min => 0, max => 100);
    $self->{output}->perfdata_add(label => "cpu_15min",
                                  value => $cpu15min,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn15min'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit15min'),
                                  min => 0, max => 100);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Juniper cpu usage (NETSCREEN-RESOURCE-MIB).

=over 8

=item B<--warning>

Threshold warning in percent (1min,5min,15min).

=item B<--critical>

Threshold critical in percent (1min,5min,15min).

=back

=cut
    
