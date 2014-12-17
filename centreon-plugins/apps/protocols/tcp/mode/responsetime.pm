###############################################################################
# Copyright 2005-2013 MERETHIS
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
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Author : Simon BOMM <sbomm@merethis.com>
#
# Based on De Bodt Lieven plugin
####################################################################################

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

    if (!defined($self->{option_results}->{port})) {
        $self->{option_results}->{port} = centreon::plugins::httplib::get_port($self);
    }
    
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

IP Addr/FQDN of the imap host

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
