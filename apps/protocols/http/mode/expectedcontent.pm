#
# Copyright 2015 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package apps::protocols::http::mode::expectedcontent;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.2';
    $options{options}->add_options(arguments =>
            {
            "hostname:s"            => { name => 'hostname' },
            "http-peer-addr:s"      => { name => 'http_peer_addr' },
            "port:s"                => { name => 'port', },
            "method:s"              => { name => 'method' },
            "proto:s"               => { name => 'proto' },
            "urlpath:s"             => { name => 'url_path' },
            "credentials"           => { name => 'credentials' },
            "ntlm"                  => { name => 'ntlm' },
            "username:s"            => { name => 'username' },
            "password:s"            => { name => 'password' },
            "proxyurl:s"            => { name => 'proxyurl' },
            "expected-string:s"     => { name => 'expected_string' },
            "timeout:s"             => { name => 'timeout' },
            "no-follow"             => { name => 'no_follow', },
            "ssl:s"                 => { name => 'ssl', },
            "cert-file:s"           => { name => 'cert_file' },
            "key-file:s"            => { name => 'key_file' },
            "cacert-file:s"         => { name => 'cacert_file' },
            "cert-pwd:s"            => { name => 'cert_pwd' },
            "cert-pkcs12"           => { name => 'cert_pkcs12' },
            "header:s@"             => { name => 'header' },
            "get-param:s@"          => { name => 'get_param' },
            "post-param:s@"         => { name => 'post_param' },
            "cookies-file:s"        => { name => 'cookies_file' },
            "unknown-status:s"      => { name => 'unknown_status' },
            "warning-status:s"      => { name => 'warning_status' },
            "critical-status:s"     => { name => 'critical_status' },
            });
    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{expected_string})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --expected-string option.");
        $self->{output}->option_exit();
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    my $webcontent = $self->{http}->request();
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

=item B<--http-peer-addr>

Set the address you want to connect (Useful if hostname is only a vhost. no ip resolve)

=item B<--port>

Port used by Webserver

=item B<--proxyurl>

Proxy URL if any

=item B<--method>

Specify http method used (Default: 'GET')

=item B<--proto>

Specify https if needed (Default: 'http')

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

Threshold for HTTP timeout (Default: 5)

=item B<--no-follow>

Do not follow http redirect

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

=item B<--header>

Set HTTP headers (Multiple option)

=item B<--get-param>

Set GET params (Multiple option. Example: --get-param='key=value')

=item B<--post-param>

Set POST params (Multiple option. Example: --post-param='key=value')

=item B<--cookies-file>

Save cookies in a file (Example: '/tmp/lwp_cookies.dat')

=item B<--unknown-status>

Threshold warning for http response code (Default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning-status>

Threshold warning for http response code

=item B<--critical-status>

Threshold critical for http response code 

=item B<--expected-string>

Specify String to check on the Webpage

=back

=cut
