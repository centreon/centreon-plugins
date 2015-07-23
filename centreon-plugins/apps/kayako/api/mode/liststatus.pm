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
# Author : Stéphane DURET <sduret@merethis.com>
#
####################################################################################

package apps::kayako::api::mode::liststatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::httplib;
use XML::XPath;
use Digest::SHA qw(hmac_sha256_base64);

my %handlers = (ALRM => {} );

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
		"hostname:s"            => { name => 'hostname' },
		"port:s"                => { name => 'port' },
		"proto:s"               => { name => 'proto', default => "http" },
		"urlpath:s"             => { name => 'url_path', default => '/api/index.php?' },
		"kayako-api-key:s"		=> { name => 'kayako_api_key' },
		"kayako-secret-key:s"	=> { name => 'kayako_secret_key' },
         });
    $self->set_signal_handlers;
    return $self;
}

sub set_signal_handlers {
    my $self = shift;

    $SIG{ALRM} = \&class_handle_ALRM;
    $handlers{ALRM}->{$self} = sub { $self->handle_ALRM() };
}

sub class_handle_ALRM {
    foreach (keys %{$handlers{ALRM}}) {
        &{$handlers{ALRM}->{$_}}();
    }
}

sub handle_ALRM {
    my $self = shift;
    
    $self->{output}->output_add(severity => 'UNKNOWN',
                                short_msg => sprintf("Cannot finished scenario execution (timeout received)"));
    $self->{output}->display();
    $self->{output}->exit();
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{timeout}) && $self->{option_results}->{timeout} =~ /^\d+$/ &&
        $self->{option_results}->{timeout} > 0) {
        alarm($self->{option_results}->{timeout});
    }
    if (!defined($self->{option_results}->{'kayako_api_key'})) {
        $self->{output}->add_option_msg(short_msg => "Please specify an API key for Kayako.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{'kayako_secret_key'})) {
        $self->{output}->add_option_msg(short_msg => "Please specify a secret key for Kayako.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
	my $salt;
	$salt .= int(rand(10)) for 1..10;
	my $digest = hmac_sha256_base64 ($salt, $self->{option_results}->{'kayako_secret_key'});
	$self->{option_results}->{'url_path'} .= "/Tickets/TicketStatus&apikey=" . $self->{option_results}->{'kayako_api_key'} . "&salt=" . $salt . "&signature=" . $digest . "=";	
	my $webcontent = centreon::plugins::httplib::connect($self);
	my $xp = XML::XPath->new( $webcontent );
	my $nodes = $xp->find('ticketstatuses/ticketstatus');

	foreach my $actionNode ($nodes->get_nodelist) {
		my ($id) = $xp->find('./id', $actionNode)->get_nodelist;
		my $trim_id = centreon::plugins::misc::trim($id->string_value);
		my ($title) = $xp->find('./title', $actionNode)->get_nodelist;
		my $trim_title = centreon::plugins::misc::trim($title->string_value);
        $self->{output}->output_add(long_msg => "'" . $trim_title . "' [id = " . $trim_id . "]");
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List status:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

List departmentf of kayako 

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host (required)

=item B<--port>

Port used by Apache

=item B<--proto>

Specify https if needed

=item B<--proxyurl>

Proxy URL if any

=item B<--kayako-api-url>

This is the URL you should dispatch all GET, POST, PUT & DELETE requests to.

=item B<--kayako-api-key>

This is your unique API key.

=item B<--kayako-secret-key>

The secret key is used to sign all the requests dispatched to Kayako.

=back

=cut
