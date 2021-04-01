#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package centreon::common::dell::fastpath::snmp::mode::cpu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning:s'  => { name => 'warning', default => '' },
        'critical:s' => { name => 'critical', default => '' },
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

sub run {
    my ($self, %options) = @_;
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
