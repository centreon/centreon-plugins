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

package apps::protocols::http::mode::expectedcontent;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::http;
use Time::HiRes qw(gettimeofday tv_interval);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'size', display_ok => 0, set => {
                key_values => [ { name => 'size' } ],
                output_template => 'Content size : %s',
                perfdatas => [
                    { label => 'size', value => 'size_absolute', template => '%s', min => 0, unit => 'B' },
                ],
            }
        },
        { label => 'time', display_ok => 0, set => {
                key_values => [ { name => 'time' } ],
                output_template => 'Response time : %.3fs',
                perfdatas => [
                    { label => 'time', value => 'time_absolute', template => '%.3f', min => 0, unit => 's' },
                ],
            }
        },
        { label => 'extracted', display_ok => 0, set => {
                key_values => [ { name => 'extracted' } ],
                output_template => 'Extracted value : %s',
                perfdatas => [
                    { label => 'value', value => 'extracted_absolute', template => '%s' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.2';
    $options{options}->add_options(arguments => {
        "hostname:s"            => { name => 'hostname' },
        "port:s"                => { name => 'port', },
        "method:s"              => { name => 'method' },
        "proto:s"               => { name => 'proto' },
        "urlpath:s"             => { name => 'url_path' },
        "credentials"           => { name => 'credentials' },
        "basic"                 => { name => 'basic' },
        "ntlmv2"                => { name => 'ntlmv2' },
        "username:s"            => { name => 'username' },
        "password:s"            => { name => 'password' },
        "expected-string:s"     => { name => 'expected_string' },
        "timeout:s"             => { name => 'timeout' },
        "no-follow"             => { name => 'no_follow', },
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
    
    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{expected_string})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --expected-string option.");
        $self->{output}->option_exit();
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub manage_selection {
    my ($self, %options) = @_;

    my $timing0 = [gettimeofday];
    my $webcontent = $self->{http}->request();
    my $timeelapsed = tv_interval($timing0, [gettimeofday]);
    
    $self->{global} = { time => $timeelapsed };
    
    $self->{output}->output_add(long_msg => $webcontent);

    if ($webcontent =~ /$self->{option_results}->{expected_string}/mi) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("'%s' is present in content.", $self->{option_results}->{expected_string}));
    } else {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("'%s' is not present in content.", $self->{option_results}->{expected_string}));
    }
    
    my $extracted = $1;
    if (defined($extracted) && $extracted =~ /(\d+([\.,]\d+)?)/) {
        $extracted = $1;
        $extracted =~ s/,/\./;
        $self->{global}->{extracted} = $extracted;
    }

    # Size check
    {
        require bytes;

        $self->{global}->{size} = bytes::length($webcontent);
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

=item B<--method>

Specify http method used (Default: 'GET')

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--urlpath>

Set path to get Webpage (Default: '/')

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

Threshold warning for http response code (Default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning-status>

Threshold warning for http response code

=item B<--critical-status>

Threshold critical for http response code 

=item B<--warning-time>

Threshold warning in seconds (Webpage response time)

=item B<--critical-time>

Threshold critical in seconds (Webpage response time)

=item B<--warning-size>

Threshold warning for content size

=item B<--critical-size>

Threshold critical for content size

=item B<--warning-extracted>

Threshold warning for extracted value

=item B<--critical-extracted>

Threshold critical for extracted value

=item B<--expected-string>

Specify String to check on the Webpage

=back

=cut
