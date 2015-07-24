###############################################################################
# Copyright 2005-2015 CENTREON
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
# As a special exception, the copyright holders of this program give CENTREON
# permission to link this program with independent modules to produce an timeelapsedutable,
# regardless of the license terms of these independent modules, and to copy and
# distribute the resulting timeelapsedutable under terms of CENTREON choice, provided that
# CENTREON also meet, for each linked independent module, the terms  and conditions
# of the license of that module. An independent module is a module which is not
# derived from this program. If you modify this program, you may extend this
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Authors : Mathieu Cinquin <mcinquin@centreon.com>
#
####################################################################################

package apps::docker::mode::image;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::httplib;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "hostname:s"            => { name => 'hostname' },
            "port:s"                => { name => 'port', default => '2376'},
            "proto:s"               => { name => 'proto', default => 'https' },
            "urlpath:s"             => { name => 'url_path', default => '/' },
            "name:s"                => { name => 'name' },
            "id:s"                  => { name => 'id' },
            "image:s"               => { name => 'image' },
            "registry-hostname:s"   => { name => 'registry_hostname' },
            "registry-proto:s"      => { name => 'registry_proto', default => 'https' },
            "registry-port:s"       => { name => 'registry_port' },
            "credentials"           => { name => 'credentials' },
            "username:s"            => { name => 'username' },
            "password:s"            => { name => 'password' },
            "ssl:s"                 => { name => 'ssl', },
            "cert-file:s"           => { name => 'cert_file' },
            "key-file:s"            => { name => 'key_file' },
            "cacert-file:s"         => { name => 'cacert_file' },
            "timeout:s"             => { name => 'timeout', default => '3' },
        });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the hostname option");
        $self->{output}->option_exit();
    }

    if ((defined($self->{option_results}->{credentials})) && (!defined($self->{option_results}->{username}) || !defined($self->{option_results}->{password}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= options when --credentials is used");
        $self->{output}->option_exit();
    }

    if ((defined($self->{option_results}->{name})) && (defined($self->{option_results}->{id}))) {
        $self->{output}->add_option_msg(short_msg => "Please set the name or id option");
        $self->{output}->option_exit();
    }

    if ((!defined($self->{option_results}->{name})) && (!defined($self->{option_results}->{id}))) {
        $self->{output}->add_option_msg(short_msg => "Please set the name or id option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{image})) {
        $self->{output}->add_option_msg(short_msg => "Please set the image option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{registry_hostname})) {
        $self->{output}->add_option_msg(short_msg => "Please set the registry-hostname option");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{registry_proto})) {
        $self->{output}->add_option_msg(short_msg => "Please set the registry-proto option");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my ($jsoncontent,$jsoncontent2);

    if (defined($self->{option_results}->{id})) {
        $self->{option_results}->{url_path} = "/containers/".$self->{option_results}->{id}."/json";
        $jsoncontent = centreon::plugins::httplib::connect($self, connection_exit => 'critical');
    } elsif (defined($self->{option_results}->{name})) {
        $self->{option_results}->{url_path} = "/containers/".$self->{option_results}->{name}."/json";
        $jsoncontent = centreon::plugins::httplib::connect($self, connection_exit => 'critical');
    }

    my $json = JSON->new;

    my ($webcontent,$webcontent2);

    eval {
        $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    my $container_id = $webcontent->{Image};

    $self->{option_results}->{url_path} = "/v1/repositories/".$self->{option_results}->{image}."/tags";
    $self->{option_results}->{port} = $self->{option_results}->{registry_port};
    $self->{option_results}->{proto} = $self->{option_results}->{registry_proto};
    $self->{option_results}->{hostname} = $self->{option_results}->{registry_hostname};

    $jsoncontent2 = centreon::plugins::httplib::connect($self, connection_exit => 'critical');

    my $json2 = JSON->new;

    eval {
        $webcontent2 = $json2->decode($jsoncontent2);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    my $result;

    foreach (@{$webcontent2}) {
        if (($container_id =~ /^$_->{layer}\w+$/)) {
            $result="1";
            last;
        }
    }

    if ($result eq "1") {
        $self->{output}->output_add(severity => "OK",
                                    short_msg => sprintf("Container's image and Registry image are identical"));
    } else {
        $self->{output}->output_add(severity => "CRITICAL",
                                    short_msg => sprintf("Container's image and Registry image are different"));
    }

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Container's image viability with a registry

=over 8

=item B<--hostname>

IP Addr/FQDN of Docker's API

=item B<--port>

Port used by Docker's API (Default: '2576')

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--urlpath>

Set path to get Docker's container information (Default: '/')

=item B<--id>

Specify the container's id

=item B<--name>

Specify the container's name

=item B<--image>

Specify the image's name

=item B<--registry-hostname>

IP Addr/FQDN of Docker's Registry

=item B<--registry-port>

Port used by Docker's Registry

=item B<--registry-proto>

Specify https if needed (Default: 'https')

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--username>

Specify username

=item B<--password>

Specify password

=item B<--ssl>

Specify SSL version (example : 'sslv3', 'tlsv1'...)

=item B<--cert-file>

Specify certificate to send to the webserver

=item B<--key-file>

Specify key to send to the webserver

=item B<--cacert-file>

Specify root certificate to send to the webserver

=item B<--timeout>

Threshold for HTTP timeout (Default: 3)

=back

=cut
