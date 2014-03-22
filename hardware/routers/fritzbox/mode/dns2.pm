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

package hardware::routers::fritzbox::mode::dns1;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use hardware::routers::fritzbox::mode::libgetdata;

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
                                  "warning:s"           => { name => 'warning', default => '' },
                                  "critical:s"          => { name => 'critical', default => '' },
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
}

sub run {
    my ($self, %options) = @_;
    my $exit_code;

    $self->{pfad} = '/upnp/control/WANIPConn1';
    $self->{uri} = 'urn:schemas-upnp-org:service:WANIPConnection:1';
    $self->{space} = 'GetAddonInfos';
    $self->{section} = 'NewDNSServer2';
    my $IP = hardware::routers::fritzbox::mode::libgetdata::getdata($self);
    #print $IP . "\n";

    if ($IP =~ /^((([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])[.]){3}([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5]))$/) {
        $exit_code = 'ok';
    } else {
        $exit_code = 'critical';
    };


    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Your current IP-Address is " . $IP));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

This Mode provides your current second DNS Address.
This Mode needs UPNP.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=back

=cut
