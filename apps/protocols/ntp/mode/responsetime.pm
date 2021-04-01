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

package apps::protocols::ntp::mode::responsetime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use Net::NTP;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
         {
         "hostname:s"   => { name => 'hostname' },
         "port:s"       => { name => 'port', default => 123 },
         "warning:s"    => { name => 'warning' },
         "critical:s"   => { name => 'critical' },
         "timeout:s"    => { name => 'timeout', default => 30 },
         });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $timing0 = [gettimeofday];
    
    my %ntp;
    eval {
        $Net::NTP::TIMEOUT = $self->{option_results}->{timeout};
        %ntp = get_ntp_response($self->{option_results}->{hostname}, $self->{option_results}->{port});
    };
    if ($@) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => "Couldn't connect to ntp server: " . $@);
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    
    my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Response time %.3fs", $timeelapsed));
    $self->{output}->perfdata_add(label => "time",
                                  value => sprintf('%.3f', $timeelapsed),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Ntp server response.

=over 8

=item B<--hostname>

Ntp server hostname

=item B<--port>

Port used (Default: 123)

=item B<--timeout>

Threshold for NTP timeout

=item B<--warning>

Threshold warning in seconds

=item B<--critical>

Threshold critical in seconds

=back

=cut
