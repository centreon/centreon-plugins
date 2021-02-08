#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::plugins::http;

sub custom_status_output {
    my ($self, %options) = @_;

    return $self->{result_values}->{http_code} . ' ' . $self->{result_values}->{message};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
         { label => 'status', threshold => 0, display_ok => 0, set => {
                key_values => [
                    { name => 'http_code' }, { name => 'message' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'time', nlabel => 'http.response.time.seconds', set => {
                key_values => [ { name => 'time' } ],
                output_template => 'Response time %.3fs',
                perfdatas => [
                    { label => 'time', template => '%.3f', min => 0, unit => 's' }
                ]
            }
        },
        { label => 'size', nlabel => 'http.response.size.count', display_ok => 0, set => {
                key_values => [ { name => 'size' } ],
                output_template => 'Content size : %s',
                perfdatas => [
                    { label => 'size', template => '%s', min => 0, unit => 'B' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'    => { name => 'hostname' },
        'port:s'        => { name => 'port', },
        'method:s'      => { name => 'method' },
        'proto:s'       => { name => 'proto' },
        'urlpath:s'     => { name => 'url_path' },
        'credentials'   => { name => 'credentials' },
        'basic'         => { name => 'basic' },
        'ntlmv2'        => { name => 'ntlmv2' },
        'username:s'    => { name => 'username' },
        'password:s'    => { name => 'password' },
        'timeout:s'     => { name => 'timeout' },
        'no-follow'     => { name => 'no_follow', },
        'cert-file:s'   => { name => 'cert_file' },
        'key-file:s'    => { name => 'key_file' },
        'cacert-file:s' => { name => 'cacert_file' },
        'cert-pwd:s'    => { name => 'cert_pwd' },
        'cert-pkcs12'   => { name => 'cert_pkcs12' },
        'header:s@'            => { name => 'header' },
        'get-param:s@'         => { name => 'get_param' },
        'post-param:s@'        => { name => 'post_param' },
        'cookies-file:s'       => { name => 'cookies_file' },
        'unknown-status:s'     => { name => 'unknown_status', default => '' },
        'warning-status:s'     => { name => 'warning_status' },
        'critical-status:s'    => { name => 'critical_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
        'warning:s'            => { name => 'warning' },
        'critical:s'           => { name => 'critical' }
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    # Compat
    if (defined($options{option_results}->{warning})) {
        $options{option_results}->{'warning-time'} = $options{option_results}->{warning};
        $options{option_results}->{'warning-http-response-time-seconds'} = $options{option_results}->{warning};
    }
    if (defined($options{option_results}->{critical})) {
        $options{option_results}->{'critical-time'} = $options{option_results}->{critical};
        $options{option_results}->{'critical-http-response-time-seconds'} = $options{option_results}->{critical};
    }    
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
    $self->{http}->set_options(%{$self->{option_results}});
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    my $timing0 = [gettimeofday];
    my $webcontent = $self->{http}->request(
        unknown_status => '', warning_status => '', critical_status => ''
    );
    $self->{global}->{time} = tv_interval($timing0, [gettimeofday]);
    $self->{global}->{http_code} = $self->{http}->get_code();
    $self->{global}->{message} = $self->{http}->get_message();

    {
        require bytes;
        
        $self->{global}->{size} = bytes::length($webcontent);
    }
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

=item B<--warning-time>

Threshold warning in seconds (Webpage response time)

=item B<--critical-time>

Threshold critical in seconds (Webpage response time)

=back

=cut
