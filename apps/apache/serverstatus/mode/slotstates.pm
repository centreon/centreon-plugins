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

package apps::apache::serverstatus::mode::slotstates;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use apps::apache::serverstatus::mode::libconnect;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"    => { name => 'hostname' },
            "port:s"        => { name => 'port' },
            "proto:s"       => { name => 'proto', default => "http" },
	    "credentials"   => { name => 'credentials' },
	    "username:s"    => { name => 'username' },
	    "password:s"    => { name => 'password' },
            "proxyurl:s"    => { name => 'proxyurl' },
            "warning:s"     => { name => 'warning' },
            "critical:s"    => { name => 'critical' },
            "timeout:s"     => { name => 'timeout', default => '3' },
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
    
    if (($self->{option_results}->{proto} ne 'http') && ($self->{option_results}->{proto} ne 'https')) {
        $self->{output}->add_option_msg(short_msg => "Unsupported protocol specified '" . $self->{option_results}->{proto} . "'.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{credentials} && (!defined($self->{option_results}->{username}) || !defined($self->{option_results}->{password})))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= options when --credentials is used");
        $self->{output}->option_exit();
    }

}

sub run {
    my ($self, %options) = @_;
    
    my $webcontent = apps::apache::serverstatus::mode::libconnect::connect($self);
    my @webcontentarr = split("\n", $webcontent);
    my $i = 0;
    my $ScoreBoard = "";
    my $PosPreBegin = undef;
    my $PosPreEnd = undef;
    
    while (($i < @webcontentarr) && ((!defined($PosPreBegin)) || (!defined($PosPreEnd)))) {
        if (!defined($PosPreBegin)) {
            if ( $webcontentarr[$i] =~ m/<pre>/i ) {
                $PosPreBegin = $i;
        }
        if (defined($PosPreBegin)) {
            if ( $webcontentarr[$i] =~ m/<\/pre>/i ) {
                $PosPreEnd = $i;
            }
        }
        $i++;
    }

    for ($i = $PosPreBegin; $i <= $PosPreEnd; $i++) {
        $ScoreBoard = $ScoreBoard . $webcontentarr[$i];
    }
  
    $ScoreBoard =~ s/^.*<[Pp][Rr][Ee]>//;
    $ScoreBoard =~ s/<\/[Pp][Rr][Ee].*>//;

    my $CountOpenSlots = ($ScoreBoard =~ tr/\.//);

    my $exit = $self->{perfdata}->threshold_check(value => $CountOpenSlots,
                                                 threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Free slots: %d", $CountOpenSlots));
    $self->{output}->perfdata_add(label => "freeSlots",
                                  value => $CountOpenSlots,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));
    $self->{output}->perfdata_add(label => "waiting",
            value => ($ScoreBoard =~ tr/\_//));
    $self->{output}->perfdata_add(label => "starting",
            value => ($ScoreBoard =~ tr/S//));
    $self->{output}->perfdata_add(label => "reading",
            value => ($ScoreBoard =~ tr/R//));
    $self->{output}->perfdata_add(label => "sending",
            value => ($ScoreBoard =~ tr/W//));
    $self->{output}->perfdata_add(label => "keepalive",
            value => ($ScoreBoard =~ tr/K//));
    $self->{output}->perfdata_add(label => "dns_lookup",
            value => ($ScoreBoard =~ tr/D//));
    $self->{output}->perfdata_add(label => "closing",
            value => ($ScoreBoard =~ tr/C//));
    $self->{output}->perfdata_add(label => "logging",
            value => ($ScoreBoard =~ tr/L//));
    $self->{output}->perfdata_add(label => "gracefuly_finished",
            value => ($ScoreBoard =~ tr/G//));
    $self->{output}->perfdata_add(label => "idle_cleanup_worker",
            value => ($ScoreBoard =~ tr/I//));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Apache WebServer Slots informations

=over 8

=item B<--hostname>

IP Address or FQDN of the webserver host

=item B<--port>

Port used by Apache

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Protocol used http or https

=item B<--timeout>

Threshold for HTTP timeout

=item B<--warning>

Warning Threshold on remaining free slot

=item B<--critical>

Critical Threshold on remaining free slot

=back

=cut
