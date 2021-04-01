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

package os::windows::local::mode::ntp;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use Net::NTP;

# Need to patch Net::NTP for windows and comment:
#   IO::Socket::INET6
# Otherwise, we have a "cannot determine peer address" error.

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
    if ($stdout =~ /^Source:\s+(\S+)/mi) {
        return $1;
    }
}

sub run {
    my ($self, %options) = @_;

    my $ntp_hostname = $self->{option_results}->{ntp_hostname};
    if (!defined($ntp_hostname)) {
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
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => sprintf('No ntp configuration set. Please use --ntp-hostname or set windows ntp configuration.'));
            $self->{output}->display();
            $self->{output}->exit();
        } elsif ($type =~ /NT5DS/i) {
            $ntp_server = $self->check_ntp_query();
        }
        if (!defined($ntp_server)) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => sprintf('Cannot get ntp source configuration. Please use --ntp-hostname.'));
            $self->{output}->display();
            $self->{output}->exit();
        }

        $ntp_hostname = $ntp_server;
    }

    my %ntp;
    # Need to set following patch: https://rt.cpan.org/Public/Bug/Display.html?id=59607
    eval {
        local $SIG{__WARN__} = sub { die $_[0] };
        
        %ntp = Net::NTP::get_ntp_response($ntp_hostname, $self->{option_results}->{ntp_port});
    };
    if ($@) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Couldn't connect to ntp server ($ntp_hostname): " . $@);
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    my $diff = $ntp{Offset};

    my $exit = $self->{perfdata}->threshold_check(value => $diff, 
                               threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf('Time offset %.3f second(s)', $diff));

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

Check time offset of server with ntp server.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--ntp-hostname>

Set the ntp hostname (if not set, we try to find it with w32tm command).

=item B<--ntp-port>

Set the ntp port (Default: 123).

=item B<--timeout>

Set timeout time for 'w32tm' command execution (Default: 30 sec)

=back

=cut
