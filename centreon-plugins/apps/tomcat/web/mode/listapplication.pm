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

package apps::tomcat::web::mode::listapplication;

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
            "hostname:s"            => { name => 'hostname' },
            "port:s"                => { name => 'port', default => '8080' },
            "proto:s"               => { name => 'proto', default => "http" },
            "credentials"           => { name => 'credentials' },
            "username:s"            => { name => 'username' },
            "password:s"            => { name => 'password' },
            "proxyurl:s"            => { name => 'proxyurl' },
            "timeout:s"             => { name => 'timeout', default => '3' },
            "urlpath:s"             => { name => 'url_path', default => '/manager/text/list' },
            "filter-name:s"         => { name => 'filter_name', },
            "filter-state:s"        => { name => 'filter_state', },
            "filter-path:s"         => { name => 'filter_path', },
            });

    $self->{result} = {};
    $self->{hostname} = undef;
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

}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = centreon::plugins::httplib::connect($self);  

     while ($webcontent =~ m/(.*):(.*):(.*):(.*)/g) {      
        my ($context, $state, $sessions, $contextpath) = ($1, $2, $3, $4);
               
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $context !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping context '" . $context . "': no matching filter name");
            next;
        }
        if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
            $state !~ /$self->{option_results}->{filter_state}/) {
            $self->{output}->output_add(long_msg => "Skipping context '" . $context . "': no matching filter state");
            next;
        }
        if (defined($self->{option_results}->{filter_path}) && $self->{option_results}->{filter_path} ne '' &&
            $contextpath !~ /$self->{option_results}->{filter_path}/) {
            $self->{output}->output_add(long_msg => "Skipping context '" . $context . "': no matching filter path");
            next;
        }

        $self->{result}->{$context} = {state => $state, sessions => $sessions, contextpath => $contextpath};
    }
}

sub run {
    my ($self, %options) = @_;
    
    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {
        $self->{output}->output_add(long_msg => "'" . $name . "' [state = " . $self->{result}->{$name}->{state} . ']');
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List Contexts:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(name => $name,
                                         state => $self->{result}->{$name}->{state}
                                         );
    }
}

1;

__END__

=head1 MODE

List Tomcat Application Server Contexts

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

=item B<--timeout>

Threshold for HTTP timeout

=item B<--url-path>

Path to the Tomcat Manager List (Default: Tomcat 7 '/manager/text/list')
Tomcat 6: '/manager/list'
Tomcat 7: '/manager/text/list'

=item B<--filter-name>

Filter Context name (regexp can be used).

=item B<--filter-state>

Filter state (regexp can be used).
Can be for example: 'running' or 'stopped'.

=item B<--filter-path>

Filter Context Path (regexp can be used).
Can be for example: '/STORAGE/context/test1'.

=back

=cut
