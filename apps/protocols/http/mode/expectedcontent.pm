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
# Authors : Simon BOMM <sbomm@merethis.com>
#           Mathieu Cinquin <mcinquin@centreon.com>
#
# Based on De Bodt Lieven plugin
####################################################################################

package apps::protocols::http::mode::expectedcontent;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::httplib;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.2';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"            => { name => 'hostname' },
            "port:s"                => { name => 'port', },
            "proto:s"               => { name => 'proto', default => "http" },
            "urlpath:s"             => { name => 'url_path', default => "/" },
            "credentials"           => { name => 'credentials' },
            "ntlm"                  => { name => 'ntlm' },
            "username:s"            => { name => 'username' },
            "password:s"            => { name => 'password' },
            "proxyurl:s"            => { name => 'proxyurl' },
            "expected-string:s"     => { name => 'expected_string' },
            "timeout:s"             => { name => 'timeout', default => '3' },
            "ssl:s"                 => { name => 'ssl', },
            "cert-file:s"           => { name => 'cert_file' },
            "key-file:s"            => { name => 'key_file' },
            "cacert-file:s"         => { name => 'cacert_file' },
            "cert-pwd:s"            => { name => 'cert_pwd' },
            "cert-pkcs12"           => { name => 'cert_pkcs12' },
            });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify hostname.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{expected_string})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --expected-string option.");
        $self->{output}->option_exit();
    }
    if ((defined($self->{option_results}->{credentials})) && (!defined($self->{option_results}->{username}) || !defined($self->{option_results}->{password}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --username= and --password= options when --credentials is used");
        $self->{output}->option_exit();
    }
    if ((!defined($self->{option_results}->{credentials})) && (defined($self->{option_results}->{ntlm}))) {
        $self->{output}->add_option_msg(short_msg => "--ntlm option must be used with --credentials option");
        $self->{output}->option_exit();
    }
    if ((defined($self->{option_results}->{pkcs12})) && (!defined($self->{option_results}->{cert_file}) && !defined($self->{option_results}->{cert_pwd}))) {
        $self->{output}->add_option_msg(short_msg => "You need to set --cert-file= and --cert-pwd= options when --pkcs12 is used");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{port})) {
        $self->{option_results}->{port} = centreon::plugins::httplib::get_port($self);
    }

    my $webcontent = centreon::plugins::httplib::connect($self);
    $self->{output}->output_add(long_msg => $webcontent);

    if ($webcontent =~ /$self->{option_results}->{expected_string}/mi) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("'%s' is present in content.", $self->{option_results}->{expected_string}));
    } else {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("'%s' is not present in content.", $self->{option_results}->{expected_string}));
    }
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Webpage content

=over 8

=item B<--hostname>

IP Addr/FQDN of the Webserver host

=item B<--port>

Port used by Webserver

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get Webpage (Default: '/')

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--ntlm>

Specify this option if you access webpage over ntlm authentification (Use with --credentials option)

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--ssl>

Specify SSL version (example : 'sslv3', 'tlsv1'...)

=item B<--cert-file>

Specify certificate to send to the webserver

=item B<--key-file>

Specify key to send to the webserver

=item B<--cacert-file>

Specify root certificate to send to the webserver

=item B<--cert-pwd>

Specify certificate's password

=item B<--cert-pkcs12>

Specify type of certificate (PKCS12)

=item B<--expected-string>

Specify String to check on the Webpage

=back

=cut
