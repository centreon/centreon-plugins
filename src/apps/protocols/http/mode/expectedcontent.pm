#
# Copyright 2024 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_content_threshold {
    my ($self, %options) = @_;

    $self->{instance_mode}->{content_status} = catalog_status_threshold_ng($self, %options);
    return $self->{instance_mode}->{content_status};
}

sub custom_content_output {
    my ($self, %options) = @_;

    my $msg = 'HTTP test(s)';
    if (!$self->{output}->is_status(value => $self->{instance_mode}->{content_status}, compare => 'ok', litteral => 1)) {
        my $filter = $self->{instance_mode}->{option_results}->{lc($self->{instance_mode}->{content_status}) . '-content'};
        $filter =~ s/\$values->/%/g;
        $filter =~ s/%\{expected_string\}/$self->{result_values}->{expected_string}/g;
        $msg = sprintf("Content test [filter: '%s']", $filter);
    }
    
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'content', type => 2, set => {
                key_values => [
                    { name => 'content' }, { name => 'code' }, { name => 'first_header' }, { name => 'header' },
                    { name => 'expected_string' }
                ],
                closure_custom_output => $self->can('custom_content_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check =>  $self->can('custom_content_threshold')
            }
        },
        { label => 'size', nlabel => 'http.content.size.bytes', display_ok => 0, set => {
                key_values => [ { name => 'size' } ],
                output_template => 'Content size : %s',
                perfdatas => [
                    { label => 'size', template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'time', nlabel => 'http.response.time.seconds', display_ok => 0, set => {
                key_values => [ { name => 'time' } ],
                output_template => 'Response time : %.3fs',
                perfdatas => [
                    { label => 'time', template => '%.3f', min => 0, unit => 's' }
                ]
            }
        },
        { label => 'extracted', nlabel => 'http.extracted.value.count', display_ok => 0, set => {
                key_values => [ { name => 'extracted' } ],
                output_template => 'Extracted value : %s',
                perfdatas => [
                    { label => 'value', template => '%s' }
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
        'hostname:s'            => { name => 'hostname' },
        'port:s'                => { name => 'port', },
        'method:s'              => { name => 'method' },
        'proto:s'               => { name => 'proto' },
        'urlpath:s'             => { name => 'url_path' },
        'credentials'           => { name => 'credentials' },
        'basic'                 => { name => 'basic' },
        'ntlmv2'                => { name => 'ntlmv2' },
        'username:s'            => { name => 'username' },
        'password:s'            => { name => 'password' },
        'expected-string:s'     => { name => 'expected_string' },
        'extracted-pattern:s'   => { name => 'extracted_pattern' },
        'timeout:s'             => { name => 'timeout' },
        'no-follow'             => { name => 'no_follow', },
        'cert-file:s'           => { name => 'cert_file' },
        'key-file:s'            => { name => 'key_file' },
        'cacert-file:s'         => { name => 'cacert_file' },
        'cert-pwd:s'            => { name => 'cert_pwd' },
        'cert-pkcs12'           => { name => 'cert_pkcs12' },
        'data:s'                => { name => 'data' },
        'header:s@'             => { name => 'header' },
        'get-param:s@'          => { name => 'get_param' },
        'post-param:s@'         => { name => 'post_param' },
        'cookies-file:s'        => { name => 'cookies_file' },
        'unknown-status:s'      => { name => 'unknown_status' },
        'warning-status:s'      => { name => 'warning_status' },
        'critical-status:s'     => { name => 'critical_status' }
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub load_request {
    my ($self, %options) = @_;

    $self->{options_request} = {};
    if (defined($self->{option_results}->{data}) && $self->{option_results}->{data} ne '') {
        $self->{option_results}->{method} = defined($self->{option_results}->{method}) && $self->{option_results}->{method} ne '' ?
            $self->{option_results}->{method} : 'POST';
        if (-f $self->{option_results}->{data} and -r $self->{option_results}->{data}) {
            local $/ = undef;
            my $fh;
            if (!open($fh, "<", $self->{option_results}->{data})) {
                $self->{output}->output_add(
                    severity => 'UNKNOWN',
                    short_msg => sprintf("Could not read file '%s': %s", $self->{option_results}->{data}, $!)
                );
                $self->{output}->display();
                $self->{output}->exit();
            }
            $self->{options_request}->{query_form_post} = <$fh>;
            close $fh;
        } else {
            $self->{options_request}->{query_form_post} = $self->{option_results}->{data};
        }
    }
}

sub check_options {
    my ($self, %options) = @_;

    # Legacy compat
    if (defined($options{option_results}->{expected_string}) && $options{option_results}->{expected_string} ne '') {
        $options{option_results}->{'critical-content'} = "%{content} !~ /%{expected_string}/mi";
    }
    $self->SUPER::check_options(%options);
    $self->load_request();

    $self->{http}->set_options(%{$self->{option_results}});
}

sub manage_selection {
    my ($self, %options) = @_;

    my $timing0 = [gettimeofday];
    my $webcontent = $self->{http}->request(%{$self->{options_request}});
    my $timeelapsed = tv_interval($timing0, [gettimeofday]);

    $self->{global} = { 
        time => $timeelapsed, 
        content => $webcontent,
        code => $self->{http}->get_code(),
        header => $self->{http}->get_header(),
        first_header => $self->{http}->get_first_header(),
        expected_string => defined($self->{option_results}->{expected_string}) ? $self->{option_results}->{expected_string} : ''
    };

    if (defined($self->{option_results}->{extracted_pattern}) && $self->{option_results}->{extracted_pattern} ne '' &&
        $webcontent =~ /$self->{option_results}->{extracted_pattern}/mi) {
        my $extracted = $1;
        if (defined($extracted) && $extracted =~ /(\d+([\.,]\d+)?)/) {
            $extracted =~ s/,/\./;
            $self->{global}->{extracted} = $extracted,
        }
    }

    $self->{output}->output_add(long_msg => $webcontent);

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

IP Addr/FQDN of the web server host

=item B<--port>

Port used by web server

=item B<--method>

Specify http method used (default: 'GET')

=item B<--proto>

Specify https if needed (default: 'http')

=item B<--urlpath>

Define the path of the web page to get (default: '/').

=item B<--credentials>

Specify this option if you are accessing a web page using authentication.

=item B<--username>

Specify the username for authentication (mandatory if --credentials is specified).

=item B<--password>

Specify the password for authentication (mandatory if --credentials is specified).

=item B<--basic>

Specify this option if you are accessing a web page using basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your web server.

Specify this option if you are accessing a web page using hidden basic authentication or you'll get a '404 NOT FOUND' error.

(use with --credentials)

=item B<--ntlmv2>

Specify this option if you are accessing a web page using ntlmv2 authentication (use with --credentials and --port options).

=item B<--timeout>

Define the timeout in seconds (default: 5).

=item B<--no-follow>

Do not follow http redirections.

=item B<--cert-file>

Specify the certificate to send to the web server.

=item B<--key-file>

Specify the key to send to the web server.

=item B<--cacert-file>

Specify the root certificate to send to the web server.

=item B<--cert-pwd>

Specify the certificate's password.

=item B<--cert-pkcs12>

Specify that the type of certificate is PKCS1.

=item B<--data>

Define the POST data to send int the body of the request. For JSON data, add the following option: --header='Content-Type: application/json'.

=item B<--header>

Set HTTP headers (multiple option)

=item B<--get-param>

Set GET params (multiple option. Example: --get-param='key=value')

=item B<--post-param>

Set POST params (multiple option. Example: --post-param='key=value')

=item B<--cookies-file>

Save cookies in a file (example: '/tmp/lwp_cookies.dat')

=item B<--extracted-pattern>

Define a pattern to extract a number from the returned page (use --warning-extracted and --critical-extracted option).

=item B<--expected-string>

Define the expected expression, where --expected-string='mypattern' is actually a shortcut for --critical-content='%{content} !~ /mypattern/mi'.
It is recommended to use --critical-content directly.

=item B<--unknown-status>

Warning threshold for http response code (default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning-status>

Warning threshold for http response code

=item B<--critical-status>

Critical threshold for http response code 

=item B<--warning-time>

Warning threshold in seconds (Webpage response time)

=item B<--critical-time>

Critical threshold in seconds (Webpage response time)

=item B<--warning-size>

Warning threshold for content size

=item B<--critical-size>

Critical threshold for content size

=item B<--warning-extracted>

Warning threshold for extracted value

=item B<--critical-extracted>

Critical threshold for extracted value

=item B<--unknown-content>

Set warning conditions for content page (default: '').
You can use the following variables: %{content}, %{header}, %{first_header}, %{code}

=item B<--warning-content>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{content}, %{header}, %{first_header}, %{code}

=item B<--critical-content>

Set critical threshold for content page (default: '').
You can use the following variables: %{content}, %{header}, %{first_header}, %{code}

=back

=cut
