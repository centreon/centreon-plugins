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
# Author : Florian Asche <info@florian-asche.de>
#
# Based on De Bodt Lieven plugin
# Based on Apache Mode by Simon BOMM
####################################################################################

package apps::tomcat::mode::application;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use apps::tomcat::mode::libconnect;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"    => { name => 'hostname' },
            "port:s"        => { name => 'port', default => '23002' },
            "proto:s"       => { name => 'proto', default => "http" },
            "credentials"   => { name => 'credentials' },
            "showall"       => { name => 'showall' },
            "username:s"    => { name => 'username' },
            "password:s"    => { name => 'password' },
            "proxyurl:s"    => { name => 'proxyurl' },
            "timeout:s"     => { name => 'timeout', default => '3' },
            "application:s" => { name => 'application' },
            "path:s"        => { name => 'path', default => '/manager/text/list' },
            "realm:s"       => { name => 'realm', default => 'Tomcat Manager Application' },
            });
    return $self;
}

sub check_options {

    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{option_results}->{proto} ne 'http') && ($self->{option_results}->{proto} ne 'https')) {
        $self->{output}->add_option_msg(short_msg => "Unsupported protocol specified '" . $self->{option_results}->{proto} . "'.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }
    if ((defined($self->{option_results}->{credentials})) && (!defined($self->{option_results}->{username}) || !defined($self->{option_results}->{password}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= options when --credentials is used");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{application}) && (!defined($self->{option_results}->{showall}))) {
        $self->{output}->add_option_msg(short_msg => "Please set the application option");
        $self->{output}->option_exit();
    }

}

sub run {
    my ($self, %options) = @_;
    
    my $webcontent = apps::tomcat::mode::libconnect::connect($self);   
    my $application = $self->{option_results}->{application};
    my $result = '';
    my $exit = '';

    if (defined($self->{option_results}->{showall})) {
        print $webcontent;
        $self->{output}->exit();
    };

    if ($webcontent =~ m/\/$application:(.*):.*:/i) {
        $result = $1;

        if ($result eq 'running') {
            $exit = 'OK';
        } else {
            $exit = 'CRITICAL';
        };

        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Tomcat Application " . $self->{option_results}->{application} . " has Status: " . $result));
    } else {
        $exit = 'UNKNOWN';
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Tomcat Application " . $self->{option_results}->{application} . " not found"));
    };

    $self->{output}->display();
    $self->{output}->exit();
};

1;

__END__

=head1 MODE

Check Tomcat Application Status by Tomcat Manager

=over 8

=item B<--hostname>

IP Address or FQDN of the Tomcat Application Server

=item B<--port>

Port used by Tomcat

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Protocol used http or https

=item B<--credentials>

Specify this option if you access server-status page over basic authentification

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--realm>

Credentials Realm (Default: 'Tomcat Manager Application')

=item B<--timeout>

Threshold for HTTP timeout

=item B<--application>

Name of the Tomcat Application you wanna Check

=item B<--showall>

This Function lists all Applications of your Tomcat

=item B<--path>

Path to the Tomcat Manager List (Default: '/manager/text/list')
Tomcat 6: '/manager/list'
Tomcat 7: '/manager/text/list'

=back

=cut
