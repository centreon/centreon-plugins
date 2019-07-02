#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::protocols::http::mode::response;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::plugins::http;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "hostname:s"    => { name => 'hostname' },
        "port:s"        => { name => 'port', },
        "method:s"      => { name => 'method' },
        "proto:s"       => { name => 'proto' },
        "urlpath:s"     => { name => 'url_path' },
        "credentials"   => { name => 'credentials' },
        "basic"         => { name => 'basic' },
        "ntlmv2"        => { name => 'ntlmv2' },
        "username:s"    => { name => 'username' },
        "password:s"    => { name => 'password' },
        "timeout:s"     => { name => 'timeout' },
        "no-follow"     => { name => 'no_follow', },
        "cert-file:s"   => { name => 'cert_file' },
        "key-file:s"    => { name => 'key_file' },
        "cacert-file:s" => { name => 'cacert_file' },
        "cert-pwd:s"    => { name => 'cert_pwd' },
        "cert-pkcs12"   => { name => 'cert_pkcs12' },
        "header:s@"            => { name => 'header' },
        "get-param:s@"         => { name => 'get_param' },
        "post-param:s@"        => { name => 'post_param' },
        "cookies-file:s"       => { name => 'cookies_file' },
        "unknown-status:s"     => { name => 'unknown_status', default => '' },
        "warning-status:s"     => { name => 'warning_status' },
        "critical-status:s"    => { name => 'critical_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
        "warning:s"            => { name => 'warning' },
        "critical:s"           => { name => 'critical' },
        "warning-size:s"       => { name => 'warning_size' },
        "critical-size:s"      => { name => 'critical_size' },
    });
    
    $self->{http} = centreon::plugins::http->new(%options);
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
    if (($self->{perfdata}->threshold_validate(label => 'warning-size', value => $self->{option_results}->{warning_size})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-size threshold '" . $self->{option_results}->{warning_size} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-size', value => $self->{option_results}->{critical_size})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-size threshold '" . $self->{option_results}->{critical_size} . "'.");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    my $timing0 = [gettimeofday];
    my $webcontent = $self->{http}->request();
    my $timeelapsed = tv_interval($timing0, [gettimeofday]);

    $self->{output}->output_add(long_msg => $webcontent);

    my $exit = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                  threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Response time %.3fs", $timeelapsed));
    $self->{output}->perfdata_add(label => "time", unit => 's',
                                  value => sprintf('%.3f', $timeelapsed),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);
    # Size check
    {
        require bytes;
        
        my $content_size = bytes::length($webcontent);
        $exit = $self->{perfdata}->threshold_check(value => $content_size,
                                                   threshold => [ { label => 'critical-size', exit_litteral => 'critical' }, { label => 'warning-size', exit_litteral => 'warning' } ]);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Content size : %s", $content_size));
        }
        $self->{output}->perfdata_add(label => "size", unit => 'B',
                                      value => $content_size,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-size'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-size'),
                                      min => 0);
    }
                                  
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Webpage response and size.

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by Webserver

=item B<--method>

Specify http method used (Default: 'GET')

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--urlpath>

Set path to get webpage (Default: '/')

=item B<--credentials>

Specify this option if you access webpage with authentication

=item B<--username>

Specify username for authentication (Mandatory if --credentials is specified)

=item B<--password>

Specify password for authentication (Mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access webpage over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your webserver.

Specify this option if you access webpage over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(Use with --credentials)

=item B<--ntlmv2>

Specify this option if you access webpage over ntlmv2 authentication (Use with --credentials and --port options)

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=item B<--no-follow>

Do not follow http redirect

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

Threshold warning for http response code

=item B<--warning-status>

Threshold warning for http response code

=item B<--critical-status>

Threshold critical for http response code (Default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning>

Threshold warning in seconds (Webpage response time)

=item B<--critical>

Threshold critical in seconds (Webpage response time)

=back

=cut
