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

package snmp_standard::mode::loadaverage;

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
                                  "warning:s"   => { name => 'warning', default => '' },
                                  "critical:s"  => { name => 'critical', default => '' },
                                  "average"     => { name => 'average' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    ($self->{warn1}, $self->{warn5}, $self->{warn15}) = split /,/, $self->{option_results}->{warning};
    ($self->{crit1}, $self->{crit5}, $self->{crit15}) = split /,/, $self->{option_results}->{critical};
    
    if (($self->{perfdata}->threshold_validate(label => 'warn1', value => $self->{warn1})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1min) threshold '" . $self->{warn1} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn5', value => $self->{warn5})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (5min) threshold '" . $self->{warn5} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn15', value => $self->{warn15})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (15min) threshold '" . $self->{warn15} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit1', value => $self->{crit1})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1min) threshold '" . $self->{crit1} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit5', value => $self->{crit5})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (5min) threshold '" . $self->{crit5} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit15', value => $self->{crit15})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (15min) threshold '" . $self->{crit15} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
   
    my $oid_CountCpu = '.1.3.6.1.2.1.25.3.3.1.2'; 
    my $oid_CpuLoad1m = '.1.3.6.1.4.1.2021.10.1.3.1';
    my $oid_CpuLoad5m = '.1.3.6.1.4.1.2021.10.1.3.2';
    my $oid_CpuLoad15m = '.1.3.6.1.4.1.2021.10.1.3.3';

    my $result = $self->{snmp}->get_leef(oids => [$oid_CpuLoad1m, $oid_CpuLoad5m, $oid_CpuLoad15m], nothing_quit => 1);
    
    my ($msg, $cpu_load1, $cpu_load5, $cpu_load15);

    if (defined($self->{option_results}->{average})) {    
        my $result2 = $self->{snmp}->get_table(oid => $oid_CountCpu);
        if (scalar(keys %$result2) <= 0){
            $self->{output}->output_add(severity => 'unknown',
                                        short_msg => 'Unable to get number of CPUs');
            $self->{output}->display();
            $self->{output}->exit();    
        }

        my $countCpu = scalar(keys %$result2);

        $cpu_load1 = sprintf("%0.2f", $result->{$oid_CpuLoad1m} / $countCpu);
        $cpu_load5 = sprintf("%0.2f", $result->{$oid_CpuLoad5m} / $countCpu);
        $cpu_load15 = sprintf("%0.2f", $result->{$oid_CpuLoad15m} / $countCpu);
        $msg = sprintf("Load average: %s [%s/%s CPUs], %s [%s/%s CPUs], %s [%s/%s CPUs]", $cpu_load1, $result->{$oid_CpuLoad1m}, $countCpu,
                       $cpu_load5, $result->{$oid_CpuLoad5m}, $countCpu,
                       $cpu_load15, $result->{$oid_CpuLoad15m}, $countCpu);
        $self->{output}->perfdata_add(label => 'avg_load1',
                                  value => $cpu_load1,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1'),
                                  min => 0);
        $self->{output}->perfdata_add(label => 'avg_load5',
                                  value => $cpu_load5,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5'),
                                  min => 0);
        $self->{output}->perfdata_add(label => 'avg_load15',
                                  value => $cpu_load15,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn15'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit15'),
                                  min => 0);
         $self->{output}->perfdata_add(label => 'load1',
                                  value => $result->{$oid_CpuLoad1m},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1', op => '*', value => $countCpu),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1', op => '*', value => $countCpu),
                                  min => 0);
        $self->{output}->perfdata_add(label => 'load5',
                                  value => $result->{$oid_CpuLoad5m},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5', op => '*', value => $countCpu),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5', op => '*', value => $countCpu),
                                  min => 0);
        $self->{output}->perfdata_add(label => 'load15',
                                  value => $result->{$oid_CpuLoad15m},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn15', op => '*', value => $countCpu),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit15', op => '*', value => $countCpu),
                                  min => 0);
    } else {
        $cpu_load1 = $result->{$oid_CpuLoad1m};
        $cpu_load5 = $result->{$oid_CpuLoad5m};
        $cpu_load15 = $result->{$oid_CpuLoad15m};
    
        $msg = sprintf("Load average: %s, %s, %s", $cpu_load1, $cpu_load5, $cpu_load15);
        $self->{output}->perfdata_add(label => 'load1',
                                  value => $cpu_load1,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1'),
                                  min => 0);
        $self->{output}->perfdata_add(label => 'load5',
                                  value => $cpu_load5,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5'),
                                  min => 0);
        $self->{output}->perfdata_add(label => 'load15',
                                  value => $cpu_load15,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn15'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit15'),
                                  min => 0);
    }
    
    my $exit1 = $self->{perfdata}->threshold_check(value => $cpu_load1,
                                                   threshold => [ { label => 'crit1', 'exit_litteral' => 'critical' }, { label => 'warn1', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $cpu_load5,
                                                   threshold => [ { label => 'crit5', 'exit_litteral' => 'critical' }, { label => 'warn5', exit_litteral => 'warning' } ]);
    my $exit3 = $self->{perfdata}->threshold_check(value => $cpu_load15,
                                                   threshold => [ { label => 'crit15', 'exit_litteral' => 'critical' }, { label => 'warn15', exit_litteral => 'warning' } ]);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3 ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => $msg);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system load-average.

=over 8

=item B<--warning>

Threshold warning (1min,5min,15min).

=item B<--critical>

Threshold critical (1min,5min,15min).

=item B<--average>

Load average for the number of CPUs.

=back

=cut
