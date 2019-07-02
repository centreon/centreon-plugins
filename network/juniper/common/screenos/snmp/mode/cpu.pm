#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::juniper::common::screenos::snmp::mode::cpu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
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
    
    ($self->{warn1m}, $self->{warn5m}, $self->{warn15m}) = split /,/, $self->{option_results}->{warning};
    ($self->{crit1m}, $self->{crit5m}, $self->{crit15m}) = split /,/, $self->{option_results}->{critical};
    
    if (($self->{perfdata}->threshold_validate(label => 'warn1min', value => $self->{warn1m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1min) threshold '" . $self->{warn1m} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn5min', value => $self->{warn5m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (5min) threshold '" . $self->{warn5m} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn15min', value => $self->{warn15m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (15min) threshold '" . $self->{warn15m} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit1min', value => $self->{crit1m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1min) threshold '" . $self->{crit1m} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit5min', value => $self->{crit5m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (5min) threshold '" . $self->{crit5m} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit15min', value => $self->{crit15m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (15min) threshold '" . $self->{crit15m} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
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
                           threshold => [ { label => 'crit1min', exit_litteral => 'critical' }, { label => 'warn1min', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $cpu5min, 
                           threshold => [ { label => 'crit5min', exit_litteral => 'critical' }, { label => 'warn5min', exit_litteral => 'warning' } ]);
    my $exit3 = $self->{perfdata}->threshold_check(value => $cpu15min, 
                           threshold => [ { label => 'crit15min', exit_litteral => 'critical' }, { label => 'warn15min', exit_litteral => 'warning' } ]);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3 ]);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("CPU Usage: %.2f%% (1min), %.2f%% (5min), %.2f%% (15min)",
                                      $cpu1min, $cpu5min, $cpu15min));
    
    $self->{output}->perfdata_add(label => "cpu_1min", unit => '%',
                                  value => $cpu1min,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1min'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1min'),
                                  min => 0, max => 100);
    $self->{output}->perfdata_add(label => "cpu_5min", unit => '%',
                                  value => $cpu5min,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn5min'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit5min'),
                                  min => 0, max => 100);
    $self->{output}->perfdata_add(label => "cpu_15min", unit => '%',
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
    
