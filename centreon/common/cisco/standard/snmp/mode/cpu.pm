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

package centreon::common::cisco::standard::snmp::mode::cpu;

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
    
    if (($self->{perfdata}->threshold_validate(label => 'warn5s', value => $self->{warn5s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (5sec) threshold '" . $self->{warn5s} . "'.");
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
    if (($self->{perfdata}->threshold_validate(label => 'crit5s', value => $self->{crit5s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (5sec) threshold '" . $self->{crit5s} . "'.");
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

sub check_table_cpu {
    my ($self, %options) = @_;
    
    my $checked = 0;
    my $instances =  {};
    foreach my $oid (keys %{$self->{results}->{$options{entry}}}) {
        $oid =~ /\.([0-9]+)$/;
        next if (defined($instances->{$1}));
        $instances->{$1} = 1;        
        my $instance = $1;
        my $cpu5sec = defined($self->{results}->{$options{entry}}->{$options{sec5} . '.' . $instance}) ? sprintf("%.2f", $self->{results}->{$options{entry}}->{$options{sec5} . '.' . $instance})  : undef;
        my $cpu1min = defined($self->{results}->{$options{entry}}->{$options{min1} . '.' . $instance}) ? sprintf("%.2f", $self->{results}->{$options{entry}}->{$options{min1} . '.' . $instance}) : undef;
        my $cpu5min = defined($self->{results}->{$options{entry}}->{$options{min5} . '.' . $instance}) ? sprintf("%.2f", $self->{results}->{$options{entry}}->{$options{min5} . '.' . $instance}) : undef;
                
        $checked = 1;
        my @exits;
        push @exits, $self->{perfdata}->threshold_check(value => $cpu5sec, 
                               threshold => [ { label => 'crit5s', exit_litteral => 'critical' }, { label => 'warn5s', exit_litteral => 'warning' } ]) if (defined($cpu5sec));
        push @exits, $self->{perfdata}->threshold_check(value => $cpu1min, 
                               threshold => [ { label => 'crit1m', exit_litteral => 'critical' }, { label => 'warn1m', exit_litteral => 'warning' } ]) if (defined($cpu1min));
        push @exits, $self->{perfdata}->threshold_check(value => $cpu5min, 
                               threshold => [ { label => 'crit5m', exit_litteral => 'critical' }, { label => 'warn5m', exit_litteral => 'warning' } ]) if (defined($cpu5min));
        my $exit = $self->{output}->get_most_critical(status => \@exits);
        
        $self->{output}->output_add(long_msg => sprintf("CPU '%s': %s (5sec), %s (1min), %s (5min)", $instance,
                                            defined($cpu5sec) ? $cpu5sec . '%' : 'not defined',
                                            defined($cpu1min) ? $cpu1min . '%' : 'not defined',
                                            defined($cpu5min) ? $cpu5min . '%' : 'not defined'));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("CPU '%s': %s (5sec), %s (1min), %s (5min)", $instance,
                                            defined($cpu5sec) ? $cpu5sec . '%' : 'not defined',
                                            defined($cpu1min) ? $cpu1min . '%' : 'not defined',
                                            defined($cpu5min) ? $cpu5min . '%' : 'not defined'));
        }
        
        if (defined($cpu5sec)) {
            $self->{output}->perfdata_add(label => "cpu_" . $instance . "_5s",
                                          value => $cpu5sec,
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5s'),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5s'),
                                          min => 0, max => 100);
        }
        if (defined($cpu1min)) {
            $self->{output}->perfdata_add(label => "cpu_" . $instance . "_1m",
                                          value => $cpu1min,
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1m'),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1m'),
                                          min => 0, max => 100);
        }
        if (defined($cpu5min)) {
            $self->{output}->perfdata_add(label => "cpu_" . $instance . "_5m",
                                          value => $cpu5min,
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5m'),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5m'),
                                          min => 0, max => 100);
        }
    }
    
    return $checked;
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    # Cisco IOS Software releases later to 12.0(3)T and prior to 12.2(3.5)
    my $oid_cpmCPUTotalEntry = '.1.3.6.1.4.1.9.9.109.1.1.1.1';
    my $oid_cpmCPUTotal5sec = '.1.3.6.1.4.1.9.9.109.1.1.1.1.3';
    my $oid_cpmCPUTotal1min = '.1.3.6.1.4.1.9.9.109.1.1.1.1.4';
    my $oid_cpmCPUTotal5min = '.1.3.6.1.4.1.9.9.109.1.1.1.1.5';
    # Cisco IOS Software releases 12.2(3.5) or later
    my $oid_cpmCPUTotal5minRev = '.1.3.6.1.4.1.9.9.109.1.1.1.1.8';
    my $oid_cpmCPUTotal1minRev = '.1.3.6.1.4.1.9.9.109.1.1.1.1.7';
    my $oid_cpmCPUTotal5secRev = '.1.3.6.1.4.1.9.9.109.1.1.1.1.6';
    # Cisco IOS Software releases prior to 12.0(3)T
    my $oid_lcpu = '.1.3.6.1.4.1.9.2.1';
    my $oid_busyPer = '.1.3.6.1.4.1.9.2.1.56'; # .0 in reality
    my $oid_avgBusy1 = '.1.3.6.1.4.1.9.2.1.57'; # .0 in reality
    my $oid_avgBusy5 = '.1.3.6.1.4.1.9.2.1.58'; # .0 in reality
    
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ 
                                                            { oid => $oid_cpmCPUTotalEntry,
                                                              start => $oid_cpmCPUTotal5sec, end => $oid_cpmCPUTotal5minRev
                                                            },
                                                            { oid => $oid_lcpu,
                                                              start => $oid_busyPer, end => $oid_avgBusy5 }],
                                                   nothing_quit => 1);
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All CPUs are ok.');
    
    if (!$self->check_table_cpu(entry => $oid_cpmCPUTotalEntry, sec5 => $oid_cpmCPUTotal5secRev, min1 => $oid_cpmCPUTotal1minRev, min5 => $oid_cpmCPUTotal5minRev)
        && !$self->check_table_cpu(entry => $oid_cpmCPUTotalEntry, sec5 => $oid_cpmCPUTotal5sec, min1 => $oid_cpmCPUTotal1min, min5 => $oid_cpmCPUTotal5min)
        && !$self->check_table_cpu(entry => $oid_lcpu, sec5 => $oid_busyPer, min1 => $oid_avgBusy1, min5 => $oid_avgBusy5)
       ) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf("Cannot find CPU informations."));
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check cpu usage (CISCO-PROCESS-MIB).

=over 8

=item B<--warning>

Threshold warning in percent (5s,1min,5min).

=item B<--critical>

Threshold critical in percent (5s,1min,5min).

=back

=cut
