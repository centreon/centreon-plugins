#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package os::windows::local::mode::ntp;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use Net::NTP;
use IO::Socket;
use Time::HiRes;

# The NTP exchange is performed directly in run() (UDP socket + select()-based
# timeout) rather than through Net::NTP::get_ntp_response(): on Windows the
# alarm()/$SIG{ALRM} timeout used by that function does not interrupt a blocking
# recv(), so a non-responding server would make the plugin hang forever.
# We also create the socket with IO::Socket::INET explicitly (not INET6) to
# avoid the Windows "cannot determine peer address" error.

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'ntp-hostname:s' => { name => 'ntp_hostname' },
        'ntp-port:s'     => { name => 'ntp_port', default => 123 },
        'warning:s'      => { name => 'warning' },
        'critical:s'     => { name => 'critical' },
        'timeout:s'      => { name => 'timeout', default => 30 },
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
}

sub check_ntp_query {
    my ($self, %options) = @_;

    my ($stdout) = centreon::plugins::misc::windows_execute(
        output => $self->{output},
        timeout => $self->{option_results}->{timeout},
        command => 'w32tm /query /status',
        command_path => undef,
        command_options => undef,
        no_quit => 1
    );
    if ($stdout =~ /^Source.*?:\s+(\S+)/mi) {
        return $1;
    }
}

sub run {
    my ($self, %options) = @_;

    my $ntp_hostname = $self->{option_results}->{ntp_hostname};
    if (!defined($ntp_hostname) || $ntp_hostname eq '') {
        my ($stdout) = centreon::plugins::misc::windows_execute(
            output => $self->{output},
            timeout => $self->{option_results}->{timeout},
            command => 'w32tm /dumpreg /subkey:parameters',
            command_path => undef,
            command_options => undef
        );
        my ($type, $ntp_server);
        $stdout =~ /^Type\s+\S+\s+(\S+)/mi;
        $type = $1;
        if ($stdout =~ /^NtpServer\s+\S+\s+(\S+)/mi) {
            ($ntp_server, my $flag) = split /,/, $1;
        }
        # type can be: 
        #   NoSync: The client does not synchronize time)
        #   NTP: The client synchronizes time from an external time source
        #   NT5DS: The client is configured to use the domain hierarchy for its time synchronization
        #   AllSync: The client synchronizes time from any available time source, including domain hierarchy and external time sources
        if ($type =~ /NoSync/i) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => sprintf('No ntp configuration set. Please use --ntp-hostname or set windows ntp configuration.')
            );
            $self->{output}->display();
            $self->{output}->exit();
        } elsif ($type =~ /NT5DS/i) {
            $ntp_server = $self->check_ntp_query();
        }
        if (!defined($ntp_server)) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => sprintf('Cannot get ntp source configuration. Please use --ntp-hostname.')
            );
            $self->{output}->display();
            $self->{output}->exit();
        }

        $ntp_hostname = $ntp_server;
    }

    my $diff;
    eval {
        local $SIG{__WARN__} = sub { die $_[0] };

        my $sock = IO::Socket::INET->new(
            Proto    => 'udp',
            PeerHost => $ntp_hostname,
            PeerPort => $self->{option_results}->{ntp_port}
        );
        die "socket creation failed: $@\n" if (!defined($sock));

        my $xmttime = Time::HiRes::time();
        my $packet = Net::NTP::Packet->new_client_packet($xmttime);
        $sock->send($packet->encode())
            or die "send() failed: $!\n";

        # select()-based timeout: works on sockets under Windows, unlike the
        # alarm()/$SIG{ALRM} mechanism of Net::NTP::get_ntp_response().
        my $rin = '';
        vec($rin, fileno($sock), 1) = 1;
        my $nfound = select($rin, undef, undef, $self->{option_results}->{timeout});
        die "timeout while waiting for NTP response\n" if (!defined($nfound) || $nfound <= 0);

        my $data;
        $sock->recv($data, 960)
            or die "recv() failed: $!\n";
        my $rectime = Time::HiRes::time();

        my $pkt = Net::NTP::Packet->decode($data, $rectime);
        $diff = Net::NTP->offset($pkt, $xmttime, $rectime);
    };
    if ($@) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => "Couldn't connect to ntp server ($ntp_hostname): " . $@
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    my $exit = $self->{perfdata}->threshold_check(
        value => $diff, 
        threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
    );
    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf('Time offset %.3f second(s)', $diff)
    );

    $self->{output}->perfdata_add(
        label => 'offset', unit => 's',
        value => sprintf("%.3f", $diff),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check time offset of server with NTP server.

=over 8

=item B<--warning>

Time warning threshold range (in seconds), in the format -n:n (e.g., -5:5). Returns WARNING when the offset is less than -n seconds or greater than n seconds.

=item B<--critical>

Time critical threshold range (in seconds), in the format -n:n (e.g., -5:5). Returns CRITICAL when the offset is less than -n seconds or greater than n seconds.

=item B<--ntp-hostname>

Set the NTP hostname (if not set, we try to find it with C<w32tm> command).

=item B<--ntp-port>

Set the NTP port (default: 123).

=item B<--timeout>

Set timeout time for C<w32tm> command execution (default: 30 sec)

=back

=cut
