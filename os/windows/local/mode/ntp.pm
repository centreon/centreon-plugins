################################################################################
# Copyright 2005-2014 MERETHIS
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
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "ntp-hostname:s"          => { name => 'ntp_hostname' },
                                  "ntp-port:s"              => { name => 'ntp_port', default => 123 },
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                  "timeout:s"               => { name => 'timeout', default => 30 },
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

sub run {
    my ($self, %options) = @_;

    my $ntp_hostname = $self->{option_results}->{ntp_hostname};
    if (!defined($ntp_hostname)) {
        my ($stdout) = centreon::plugins::misc::windows_execute(output => $self->{output},
                                                                timeout => $self->{option_results}->{timeout},
                                                                command => 'w32tm /dumpreg /subkey:parameters',
                                                                command_path => undef,
                                                                command_options => undef);
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
                                        short_msg => sprintf("No ntp configuration set. Please use --ntp-hostname or set windows ntp configuration."));
            $self->{output}->display();
            $self->{output}->exit();
        }
        if (!defined($ntp_server)) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => sprintf("Cannot get ntp source configuration (it uses AD). Please use --ntp-hostname."));
            $self->{output}->display();
            $self->{output}->exit();
        }
        $ntp_hostname = $ntp_server;
    }

    my %ntp;

    eval {
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
                                short_msg => sprintf("Time offset %.3f second(s)", $diff));

    $self->{output}->perfdata_add(label => 'offset', unit => 's',
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
