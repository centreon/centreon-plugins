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

package network::fortinet::fortigate::common::mode::sessions;

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
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "warning-avg:s"           => { name => 'warning_avg', default => '' },
                                  "critical-avg:s"          => { name => 'critical_avg', default => '' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{critical} . "'.");
       $self->{output}->option_exit();
    }
    
    ($self->{warn1}, $self->{warn10}, $self->{warn30}, $self->{warn60}) = split /,/, $self->{option_results}->{warning_avg};
    ($self->{crit1}, $self->{crit10}, $self->{crit30}, $self->{warn60}) = split /,/, $self->{option_results}->{critical_avg};
    
    if (($self->{perfdata}->threshold_validate(label => 'warn1', value => $self->{warn1})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning (1min) threshold '" . $self->{warn1} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn10', value => $self->{warn10})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning (10min) threshold '" . $self->{warn10} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn30', value => $self->{warn30})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning (30min) threshold '" . $self->{warn30} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn60', value => $self->{warn60})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning (60min) threshold '" . $self->{warn60} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit1', value => $self->{crit1})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical (1min) threshold '" . $self->{crit1} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit10', value => $self->{crit10})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical (10min) threshold '" . $self->{crit10} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit30', value => $self->{crit30})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical (30min) threshold '" . $self->{crit30} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit60', value => $self->{crit60})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical (60min) threshold '" . $self->{crit60} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_fgSysSesCount = '.1.3.6.1.4.1.12356.101.4.1.8.0';
    my $oid_fgSysSesRate1 = '.1.3.6.1.4.1.12356.101.4.1.11.0';
    my $oid_fgSysSesRate10 = '.1.3.6.1.4.1.12356.101.4.1.12.0';
    my $oid_fgSysSesRate30 = '.1.3.6.1.4.1.12356.101.4.1.13.0';
    my $oid_fgSysSesRate60 = '.1.3.6.1.4.1.12356.101.4.1.14.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_fgSysSesCount, $oid_fgSysSesRate1, 
                                                  $oid_fgSysSesRate10, $oid_fgSysSesRate30, $oid_fgSysSesRate60], nothing_quit => 1);
    
    my $exit = $self->{perfdata}->threshold_check(value => $result->{$oid_fgSysSesCount}, 
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Current active sessions: %d", $result->{$oid_fgSysSesCount}));
    $self->{output}->perfdata_add(label => "sessions",
                                  value => $result->{$oid_fgSysSesCount},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);
    
    my $exit1 = $self->{perfdata}->threshold_check(value => $result->{$oid_fgSysSesRate1}, 
                               threshold => [ { label => 'crit1', 'exit_litteral' => 'critical' }, { label => 'warn1', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $result->{$oid_fgSysSesRate10}, 
                               threshold => [ { label => 'crit10', 'exit_litteral' => 'critical' }, { label => 'warn10', exit_litteral => 'warning' } ]);
    my $exit3 = $self->{perfdata}->threshold_check(value => $result->{$oid_fgSysSesRate30}, 
                               threshold => [ { label => 'crit30', 'exit_litteral' => 'critical' }, { label => 'warn30', exit_litteral => 'warning' } ]);
    my $exit4 = $self->{perfdata}->threshold_check(value => $result->{$oid_fgSysSesRate60}, 
                               threshold => [ { label => 'crit60', 'exit_litteral' => 'critical' }, { label => 'warn60', exit_litteral => 'warning' } ]);
    $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3, $exit4 ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Averate session setup rate: %s, %s, %s, %s (1min, 10min, 30min, 60min)", 
                                                      $result->{$oid_fgSysSesRate1}, $result->{$oid_fgSysSesRate10}, 
                                                      $result->{$oid_fgSysSesRate30}, $result->{$oid_fgSysSesRate60}));
            
    $self->{output}->perfdata_add(label => 'session_avg_setup1',
                                  value => $result->{$oid_fgSysSesRate1},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1'),
                                  min => 0);
    $self->{output}->perfdata_add(label => 'session_avg_setup10',
                                  value => $result->{$oid_fgSysSesRate10},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn10'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit10'),
                                  min => 0);
    $self->{output}->perfdata_add(label => 'session_avg_setup30',
                                  value => $result->{$oid_fgSysSesRate30},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn30'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit30'),
                                  min => 0);
    $self->{output}->perfdata_add(label => 'session_avg_setup60',
                                  value => $result->{$oid_fgSysSesRate60},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn60'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit60'),
                                  min => 0);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check sessions (FORTINET-FORTIGATE-MIB).

=over 8

=item B<--warning>

Threshold warning of current active sessions.

=item B<--critical>

Threshold critical of current active sessions.

=item B<--warning-avg>

Threshold warning of average setup rate (1min,10min,30min,60min).

=item B<--critical-avg>

Threshold critical of average setup rate (1min,10min,30min,60min).

=back

=cut
    