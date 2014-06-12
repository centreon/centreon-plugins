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

package apps::protocols::http::mode::expectedcontent;

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
    if (($self->{perfdata}->threshold_validate(label => 'warning-bytes', value => $self->{option_results}->{warning_bytes})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-bytes threshold '" . $self->{option_results}->{warning_bytes} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-bytes', value => $self->{option_results}->{critical_bytes})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-bytes threshold '" . $self->{option_results}->{critical_bytes} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-access', value => $self->{option_results}->{warning_access})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-access threshold '" . $self->{option_results}->{warning_access} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-access', value => $self->{option_results}->{critical_access})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-access threshold '" . $self->{option_results}->{critical_access} . "'.");
        $self->{output}->option_exit();
    }
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
        $self->{output}->display();
        $self->{output}->exit();
    } else {
        $self->{output}->output_add(severity => 'Critical',
                                short_msg => sprintf("'%s' is not present in content.", $self->{option_results}->{expected_string}));
        $self->{output}->display();
        $self->{output}->exit();
    }
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

=back

=cut
