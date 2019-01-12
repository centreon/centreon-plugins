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

package apps::protocols::snmp::mode::responsetime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use POSIX "fmod";

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
         "warning-rt:s"    => { name => 'warning_rt' },
         "critical-rt:s"   => { name => 'critical_rt' },
         "warning-pl:s"    => { name => 'warning_pl' },
         "critical-pl:s"   => { name => 'critical_pl' },
         });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-rt', value => $self->{option_results}->{warning_rt})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-rt threshold '" . $self->{option_results}->{warning_rt} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-rt', value => $self->{option_results}->{critical_rt})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-rt threshold '" . $self->{option_results}->{critical_rt} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-pl', value => $self->{option_results}->{warning_pl})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-pl threshold '" . $self->{option_results}->{warning_pl} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-pl', value => $self->{option_results}->{critical_pl})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-pl threshold '" . $self->{option_results}->{critical_pl} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    my ($timing1, $timing2, $timeelapsed, $packetlost);
    my $sysDescr=".1.3.6.1.2.1.1.1.0";
    $timing1 = [gettimeofday];
    $self->{snmp}->get_leef(oids => [$sysDescr], nothing_quit => 0, dont_quit => 1);
    $timing2 = [gettimeofday];
    $timeelapsed = fmod((tv_interval ($timing1, $timing2) * 1000), ($self->{snmp}{snmp_params}{Timeout} / 1000));
    $packetlost = int((tv_interval ($self->{timing0}, $timing2) * 1000) / ($self->{snmp}{snmp_params}{Timeout} / 1000));
    $packetlost = $packetlost * 100 / ($packetlost + 1);

    my $exit1 = $self->{perfdata}->threshold_check(value => $timeelapsed, threshold => [ { label => 'critical-rt', exit_litteral => 'critical' }, { label => 'warning-rt', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $packetlost, threshold => [ { label => 'critical-pl', exit_litteral => 'critical' }, { label => 'warning-pl', exit_litteral => 'warning' } ]);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("SNMP agent rt %.3fms lost %d%%", $timeelapsed, $packetlost));
    $self->{output}->perfdata_add(label => 'rt',
                                  value => sprintf('%.3f', $timeelapsed),
                                  unit => 'ms',
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-rt'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-rt'),
                                  min => 0);
    $self->{output}->perfdata_add(label => 'pl',
                                  value => sprintf('%d', $packetlost),
                                  unit => '%',
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-pl'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-pl'),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check SNMP agent response time

=over 8

=item B<--warning-rt>

Response time threshold warning in milliseconds

=item B<--critical-rt>

Response time threshold critical in milliseconds

=item B<--warning-pl>

Packets lost threshold warning in %

=item B<--critical-pl>

Packets lost threshold critical in %

=back

=cut