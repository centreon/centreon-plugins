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

package hardware::sensors::sensormetrix::em01::web::mode::contact;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::httplib;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"        => { name => 'hostname' },
            "port:s"            => { name => 'port', },
            "proto:s"           => { name => 'proto', default => "http" },
            "urlpath:s"         => { name => 'url_path', default => "/index.htm?eL" },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "proxyurl:s"        => { name => 'proxyurl' },
            "warning"           => { name => 'warning' },
            "critical"          => { name => 'critical' },
            "closed"            => { name => 'closed' },
            "timeout:s"         => { name => 'timeout', default => '3' },
            });
    $self->{status} = { closed => 'ok', opened => 'ok' };
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    my $label = 'opened';
    $label = 'closed' if (defined($self->{option_results}->{closed}));
    if (defined($self->{option_results}->{critical})) {
        $self->{status}->{$label} = 'critical';
    } elsif (defined($self->{option_results}->{warning})) {
        $self->{status}->{$label} = 'warning';
    }
    
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
    if ((defined($self->{option_results}->{credentials})) && (!defined($self->{option_results}->{username}) || !defined($self->{option_results}->{password}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= options when --credentials is used");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
        
    my $webcontent = centreon::plugins::httplib::connect($self);
    my $contact;

    if ($webcontent !~ /<body>(.*)<\/body>/msi || $1 !~ /([NW]).*?:/) {
        $self->{output}->add_option_msg(short_msg => "Could not find door contact information.");
        $self->{output}->option_exit();
    }
    $contact = $1;

    if ($contact eq 'N') {
        $self->{output}->output_add(severity => $self->{status}->{opened},
                                short_msg => sprintf("Door is opened."));
    } else {
        $self->{output}->output_add(severity => $self->{status}->{closed},
                                short_msg => sprintf("Door is closed."));
    }

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check sensor contact.

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by Apache

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/index.htm?eL')

=item B<--credentials>

Specify this option if you access server-status page over basic authentification

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--warning>

Warning if door is opened (can set --close for closed door)

=item B<--critical>

Critical if door is opened (can set --close for closed door)

=item B<--closed>

Threshold is on closed door (default: opened)

=back

=cut
