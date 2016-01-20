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

package network::radware::alteon::common::mode::cpu;

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
    
    if (($self->{perfdata}->threshold_validate(label => 'warn1s', value => $self->{warn1s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1sec) threshold '" . $self->{warn1s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn4s', value => $self->{warn4s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (4sec) threshold '" . $self->{warn4s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn64s', value => $self->{warn64s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (64sec) threshold '" . $self->{warn64s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit1s', value => $self->{crit1s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1sec) threshold '" . $self->{crit1s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit4s', value => $self->{crit4s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (4sec) threshold '" . $self->{crit4s} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit64s', value => $self->{crit64s})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (64sec) threshold '" . $self->{crit64s} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_mpCpuStatsUtil1Second = '.1.3.6.1.4.1.1872.2.5.1.2.2.1.0';
    my $oid_mpCpuStatsUtil4Seconds = '.1.3.6.1.4.1.1872.2.5.1.2.2.2.0';
    my $oid_mpCpuStatsUtil64Seconds = '.1.3.6.1.4.1.1872.2.5.1.2.2.3.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_mpCpuStatsUtil1Second, $oid_mpCpuStatsUtil4Seconds,
                                                  $oid_mpCpuStatsUtil64Seconds], nothing_quit => 1);
    
    my $cpu1sec = $result->{$oid_mpCpuStatsUtil1Second};
    my $cpu4sec = $result->{$oid_mpCpuStatsUtil4Seconds};
    my $cpu64sec = $result->{$oid_mpCpuStatsUtil64Seconds};
    
    my $exit1 = $self->{perfdata}->threshold_check(value => $cpu1sec, 
                           threshold => [ { label => 'crit1s', 'exit_litteral' => 'critical' }, { label => 'warn1s', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $cpu4sec, 
                           threshold => [ { label => 'crit4s', 'exit_litteral' => 'critical' }, { label => 'warn4s', exit_litteral => 'warning' } ]);
    my $exit3 = $self->{perfdata}->threshold_check(value => $cpu64sec, 
                           threshold => [ { label => 'crit64s', 'exit_litteral' => 'critical' }, { label => 'warn64s', exit_litteral => 'warning' } ]);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3 ]);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("MP CPU Usage: %.2f%% (1sec), %.2f%% (4sec), %.2f%% (64sec)",
                                      $cpu1sec, $cpu4sec, $cpu64sec));
    
    $self->{output}->perfdata_add(label => "cpu_1s", unit => '%',
                                  value => $cpu1sec,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1s'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1s'),
                                  min => 0, max => 100);
    $self->{output}->perfdata_add(label => "cpu_4s", unit => '%',
                                  value => $cpu4sec,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn4s'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit4s'),
                                  min => 0, max => 100);
    $self->{output}->perfdata_add(label => "cpu_64s", unit => '%',
                                  value => $cpu64sec,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn64s'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit64s'),
                                  min => 0, max => 100);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check MP cpu usage (ALTEON-CHEETAH-SWITCH-MIB).

=over 8

=item B<--warning>

Threshold warning in percent (1s,4s,64s).

=item B<--critical>

Threshold critical in percent (1s,4s,64s).

=back

=cut
    