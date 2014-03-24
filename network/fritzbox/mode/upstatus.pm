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
# Authors : Florian Asche <info@florian-asche.de>
#
####################################################################################

package network::fritzbox::mode::upstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use network::fritzbox::mode::libgetdata;
use POSIX;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"          => { name => 'hostname' },
                                  "port:s"              => { name => 'port', default => '49000' },
                                  "timeout:s"           => { name => 'timeout', default => 30 },
                                  "warning:s"           => { name => 'warning', },
                                  "critical:s"          => { name => 'critical',  },
                                  "seconds"             => { name => 'seconds', },
                                });
    return $self;
}

sub check_options {

    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify an Hostname.");
       $self->{output}->option_exit(); 
    }
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
    my $exit_code;
    
    network::fritzbox::mode::libgetdata::init($self, pfad => '/upnp/control/WANCommonIFC1',
                                                     uri => 'urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1');
    network::fritzbox::mode::libgetdata::call($self, soap_method => 'GetCommonLinkProperties');
    my $WANAccessType = network::fritzbox::mode::libgetdata::value($self, path => '/GetCommonLinkPropertiesResponse/NewWANAccessType');
    my $LinkStatus = network::fritzbox::mode::libgetdata::value($self, path => '/GetCommonLinkPropertiesResponse/NewPhysicalLinkStatus');

    network::fritzbox::mode::libgetdata::init($self, pfad => '/upnp/control/WANIPConn1',
                                                     uri => 'urn:schemas-upnp-org:service:WANIPConnection:1');
    network::fritzbox::mode::libgetdata::call($self, soap_method => 'GetStatusInfo');
    my $uptime = network::fritzbox::mode::libgetdata::value($self, path => '/GetStatusInfoResponse/NewUptime');
    my $ConnectionStatus = network::fritzbox::mode::libgetdata::value($self, path => '/GetStatusInfoResponse/NewConnectionStatus');

    $exit_code = $self->{perfdata}->threshold_check(value => floor($uptime),
                              threshold => [ { label => 'critical', exit_litteral => 'critical' }, 
                                             { label => 'warning', exit_litteral => 'warning' } ]);

    if ($LinkStatus !~ /^up$/i || $ConnectionStatus !~ /^connected$/i) {
        $exit_code = 'critical';
    }
    
    $self->{output}->perfdata_add(label => 'uptime',
                                  value => floor($uptime),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Physical Link is " . $LinkStatus . " and " . $WANAccessType . " is " . $ConnectionStatus .  
                                " since: %s", defined($self->{option_results}->{seconds}) ? floor($uptime) . " seconds" : floor($uptime / 86400) . " days" ));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

This Mode Checks Physical Link Status, Connection Status and Uptime of your Fritz!Box Internet Connection.
This Mode needs UPNP.

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--seconds>

Display uptime in seconds.

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=back

=cut
