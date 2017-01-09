#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::protocols::tcp::mode::responsetime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use IO::Socket::SSL;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
         "hostname:s"   => { name => 'hostname' },
         "port:s"       => { name => 'port', },
         "warning:s"    => { name => 'warning' },
         "critical:s"   => { name => 'critical' },
         "timeout:s"    => { name => 'timeout', default => '3' },
         "ssl"          => { name => 'ssl' },
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
    if (!defined($self->{option_results}->{port})) {
        $self->{output}->add_option_msg(short_msg => "Please set the port option");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    
    my ($connection, $timing0, $timeelapsed);
    if (defined($self->{option_results}->{ssl})) {
        $timing0 = [gettimeofday];
        $connection = IO::Socket::SSL->new(PeerAddr => $self->{option_results}->{hostname},
                                           PeerPort => $self->{option_results}->{port},
                                           Timeout => $self->{option_results}->{timeout},
                                           );
        $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    } else {
        $timing0 = [gettimeofday];
        $connection = IO::Socket::INET->new(PeerAddr => $self->{option_results}->{hostname},
                                            PeerPort => $self->{option_results}->{port},
                                            Timeout => $self->{option_results}->{timeout},
                                            );
        $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    }

    if (!defined($connection)) {
        if (!defined($!) || ($! eq '')) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => "Connection failed : SSL error");
        } else {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Connection failed : %s", $!));
        }
    } else {
        my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Response time %.3fs", $timeelapsed));
        $self->{output}->perfdata_add(label => 'time',
                                      value => sprintf('%.3f', $timeelapsed),
                                      unit => 's',
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check TCP connection time

=over 8

=item B<--hostname>

IP Addr/FQDN of the host

=item B<--port>

Port used

=item B<--ssl>

Use SSL connection.
(no attempt is made to check the certificate validity by default).

=item B<--timeout>

Connection timeout in seconds (Default: 3)

=item B<--warning>

Threshold warning in seconds

=item B<--critical>

Threshold critical in seconds

=back

=cut
