#
# Copyright 2016 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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

sub check_nexus_cpu {
    my ($self, %options) = @_;
    
    if (!defined($self->{results}->{$options{oid}}->{$options{oid} . '.0'})) {
        return 0;
    }
    
    my $cpu = $self->{results}->{$options{oid}}->{$options{oid} . '.0'};
    my $exit = $self->{perfdata}->threshold_check(value => $cpu, 
                                                  threshold => [ { label => 'crit5m', exit_litteral => 'critical' }, { label => 'warn5m', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("CPU Usage : %s %%", $cpu));
    $self->{output}->perfdata_add(label => "cpu", unit => '%',
                                  value => $cpu,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5m'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5m'),
                                  min => 0, max => 100);
    return 1;
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
        
        # Case that it's maybe other CPU oid in table for datas.
        next if (!defined($cpu5sec) && !defined($cpu1min) && !defined($cpu5min));
        
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
            $self->{output}->perfdata_add(label => "cpu_" . $instance . "_5s", unit => '%',
                                          value => $cpu5sec,
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5s'),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5s'),
                                          min => 0, max => 100);
        }
        if (defined($cpu1min)) {
            $self->{output}->perfdata_add(label => "cpu_" . $instance . "_1m", unit => '%',
                                          value => $cpu1min,
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1m'),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1m'),
                                          min => 0, max => 100);
        }
        if (defined($cpu5min)) {
            $self->{output}->perfdata_add(label => "cpu_" . $instance . "_5m", unit => '%',
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
    # Cisco Nexus
    my $oid_cseSysCPUUtilization = '.1.3.6.1.4.1.9.9.305.1.1.1'; # .0 in reality
    
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ 
                                                            { oid => $oid_cpmCPUTotalEntry,
                                                              start => $oid_cpmCPUTotal5sec, end => $oid_cpmCPUTotal5minRev
                                                            },
                                                            { oid => $oid_lcpu,
                                                              start => $oid_busyPer, end => $oid_avgBusy5 },
                                                            { oid => $oid_cseSysCPUUtilization },
                                                         ],
                                                         nothing_quit => 1);
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All CPUs are ok.');
    
    if (!$self->check_table_cpu(entry => $oid_cpmCPUTotalEntry, sec5 => $oid_cpmCPUTotal5secRev, min1 => $oid_cpmCPUTotal1minRev, min5 => $oid_cpmCPUTotal5minRev)
        && !$self->check_table_cpu(entry => $oid_cpmCPUTotalEntry, sec5 => $oid_cpmCPUTotal5sec, min1 => $oid_cpmCPUTotal1min, min5 => $oid_cpmCPUTotal5min)
        && !$self->check_table_cpu(entry => $oid_lcpu, sec5 => $oid_busyPer, min1 => $oid_avgBusy1, min5 => $oid_avgBusy5)
       ) {
        if (!$self->check_nexus_cpu(oid => $oid_cseSysCPUUtilization)) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => sprintf("Cannot find CPU informations."));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check cpu usage (CISCO-PROCESS-MIB and CISCO-SYSTEM-EXT-MIB).

=over 8

=item B<--warning>

Threshold warning in percent (5s,1min,5min).
Used 5min threshold when you have only 'cpu' metric.

=item B<--critical>

Threshold critical in percent (5s,1min,5min).
Used 5min threshold when you have only 'cpu' metric.

=back

=cut
