################################################################################
## Copyright 2005-2013 MERETHIS
## Centreon is developped by : Julien Mathis and Romain Le Merlus under
## GPL Licence 2.0.
## 
## This program is free software; you can redistribute it and/or modify it under 
## the terms of the GNU General Public License as published by the Free Software 
## Foundation ; either version 2 of the License.
## 
## This program is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
## PARTICULAR PURPOSE. See the GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License along with 
## this program; if not, see <http://www.gnu.org/licenses>.
## 
## Linking this program statically or dynamically with other modules is making a 
## combined work based on this program. Thus, the terms and conditions of the GNU 
## General Public License cover the whole combination.
## 
## As a special exception, the copyright holders of this program give MERETHIS 
## permission to link this program with independent modules to produce an timeelapsedutable, 
## regardless of the license terms of these independent modules, and to copy and 
## distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
## MERETHIS also meet, for each linked independent module, the terms  and conditions 
## of the license of that module. An independent module is a module which is not 
## derived from this program. If you modify this program, you may extend this 
## exception to your version of the program, but you are not obliged to do so. If you
## do not wish to do so, delete this exception statement from your version.
## 
## For more information : contact@centreon.com
## Author : Simon BOMM <sbomm@merethis.com>
##
## Based on De Bodt Lieven plugin
#####################################################################################

package apps::apache::mode::requests;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use LWP::UserAgent;
use Time::HiRes qw(gettimeofday tv_interval);

sub new {
	my ($class, %options) = @_;
	my $self = $class->SUPER::new(package => __PACKAGE__, %options);
	bless $self, $class;

	$self->{version} = '1.0';
	$options{options}->add_options(arguments =>
			{
			"hostname:s"        => { name => 'hostname' },
			"port:i"	=> { name => 'port' },
			"proto:s"	=> { name => 'proto', default => "http" },
			"proxyurl:s"	=> { name => 'proxyurl' },
			"warning:i"    => { name => 'warning' },
			"critical:i"    => { name => 'critical' },
			"warningrequest:i"    => { name => 'warningrequest' },
			"criticalrequest:i"    => { name => 'criticalrequest' },
			"timeout:i"	    => { name => 'timeout', default => '3' },
			"extended"	=> { name => 'extended'},
			});
	return $self;
}

sub check_options {

	my ($self, %options) = @_;
	$self->SUPER::init(%options);

	if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
		$self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warning} . "'.");
		$self->{output}->option_exit();
	}
	if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
		$self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{critical} . "'.");
		$self->{output}->option_exit();
	}

	if (($self->{perfdata}->threshold_validate(label => 'criticalrequest', value => $self->{option_results}->{criticalrequest})) == 0) {
		$self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warning} . "'.");
		$self->{output}->option_exit();
	}
	if (($self->{perfdata}->threshold_validate(label => 'warningrequest', value => $self->{option_results}->{warningrequest})) == 0) {
		$self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{critical} . "'.");
		$self->{output}->option_exit();
	}

}

sub run {

	my ($self, %options) = @_;
	my $ua = LWP::UserAgent->new( protocols_allowed => ['http','https'], timeout => $self->{option_results}->{timeout});
	
	my $timing0 = [gettimeofday];
	my $response = '';
	
	if ($self->{option_results}->{proto} eq "https") {
		if (defined $self->{option_results}->{proxyurl}) {
			$ua->proxy(['https'], $self->{option_results}->{proxyurl});
		}
		if (!defined $self->{option_results}->{port}) {
                        $response = $ua->get($self->{option_results}->{proto}."://" .$self->{option_results}->{hostname}.'/server-status');
                } else  {
                        $response = $ua->get('https://'.$self->{option_results}->{hostname}.':'.$self->{option_results}->{port}.'/server-status');
                }	
		
	} else {
		if (defined $self->{option_results}->{proxyurl}) {
                        $ua->proxy(['http'], $self->{option_results}->{proxyurl});
                }
		if (!defined $self->{option_results}->{port}) {
			$response = $ua->get($self->{option_results}->{proto}."://" .$self->{option_results}->{hostname}.'/server-status');
		} else  {
			$response = $ua->get('http://'.$self->{option_results}->{hostname}.':'.$self->{option_results}->{port}.'/server-status');
		}
	}

	my $timeelapsed = tv_interval ($timing0, [gettimeofday]);

	if ($response->is_success) {

		my $webcontent=$response->content;
		my @webcontentarr = split("\n", $webcontent);
		my $i = 0;
		my $rPerSec=undef;
		my $rPerSecSfx=undef;
		my $bPerSec=undef;
		my $bPerSecSfx=undef;
		my $bPerReq=undef;
		my $bPerReqSfx=undef;
		while (($i < @webcontentarr) && ((!defined($rPerSec)) || (!defined($bPerSec)) || (!defined($bPerReq)))) {
			if ($webcontentarr[$i] =~ /([0-9]*\.?[0-9]+)\s([A-Za-z]+)\/sec\s-\s([0-9]*\.?[0-9]+)\s([A-Za-z]+)\/second\s-\s([0-9]*\.?[0-9]+)\s([A-Za-z]+)\/request/) {
				($rPerSec, $rPerSecSfx, $bPerSec, $bPerSecSfx, $bPerReq, $bPerReqSfx) = ($webcontentarr[$i] =~ /([0-9]*\.?[0-9]+)\s([A-Za-z]+)\/sec\s-\s([0-9]*\.?[0-9]+)\s([A-Za-z]+)\/second\s-\s([0-9]*\.?[0-9]+)\s([A-Za-z]+)\/request/);
			}
		$i++;
		}

		my $exit1 = $self->{perfdata}->threshold_check(value => $rPerSec,
				threshold => [ { label => 'criticalrequest', 'exit_litteral' => 'critical' }, { label => 'query', exit_litteral => 'warning' } ]);
		my $exit2 = $self->{perfdata}->threshold_check(value => $timeelapsed,
				threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
		my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);

		$self->{output}->output_add(severity => $exit,
				short_msg => sprintf("RequestPerSec: %f  BytesPerSecond: %d BytesPerRequest: %d", $rPerSec, $bPerSec, $bPerReq));
		$self->{output}->perfdata_add(label => "requestPerSec",
				value => $rPerSec,
				unit => $rPerSecSfx,
				warning => $self->{option_results}->{warningrequest},
				critical => $self->{option_results}->{criticalrequest});
		$self->{output}->perfdata_add(label => "bytesPerSec",
				value => $bPerSec,
				unit => $bPerSecSfx);
		$self->{output}->perfdata_add(label => "bytesPerRequest",
				value => $bPerReq,
				unit => $bPerReqSfx);
	
	} else {
		$self->{output}->output_add(severity => 'UNKNOWN',
				short_msg => $response->status_line);
	}

	$self->{output}->display();
	$self->{output}->exit();

}

1;


__END__

=head1 MODE

Check Apache WebServer Request statistics

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by Apache

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Specify https if needed

=item B<--timeout>

Threshold for HTTP timeout

=item B<--warning>

Threshold warning in seconds (server-status page response time)

=item B<--critical>

Threshold critical in seconds (server-status page response time)

=item B<--warningrequest>

Warning Threshold for Request per seconds

=item B<--criticalrequest>

Critical Threshold for Request per seconds

=back

=cut
