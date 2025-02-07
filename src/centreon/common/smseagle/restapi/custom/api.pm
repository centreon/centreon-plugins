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

package centreon::common::smseagle::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'api-version:s'          => { name => 'api_version', default => 'v2' },
            'api-path:s'             => { name => 'api_path', default => '/api' },
            'access-token:s'         => { name => 'access_token' },
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port', default => 443 },
            'proto:s'                => { name => 'proto', default => 'https' },
            'timeout:s'              => { name => 'timeout', default => 10 },
            'unknown-http-status:s'  => {
                name    => 'unknown_http_status',
                default => '%{http_code} < 200 or %{http_code} >= 300'
            },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'SMS Eagle API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    if (centreon::plugins::misc::is_empty($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }

    if (centreon::plugins::misc::is_empty($self->{option_results}->{api_version})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-version option.');
        $self->{output}->option_exit();
    }

    if (centreon::plugins::misc::is_empty($self->{option_results}->{api_path})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-path option.');
        $self->{output}->option_exit();
    }

    if (lc($self->{option_results}->{proto}) !~ /^(|http|https)$/) {
        $self->{output}->add_option_msg(short_msg => "Unsupported --proto option.");
        $self->{output}->option_exit();
    }

    if (centreon::plugins::misc::is_empty($self->{option_results}->{access_token})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --access-token option.');
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'access-token', value => $self->{option_results}->{access_token});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub join_url_parts {
    my @parts = @_;

    # Join the parts together with '/'
    my $url = join('/', @parts);
    # Replace multiple consecutive '/' with a single '/'
    $url =~ s|/+|/|g;
    # Remove trailing '/' unless the URL is just '/'
    $url =~ s|/$|| unless $url eq '/';

    return $url;
}

sub request_api {
    my ($self, %options) = @_;

    my $get_param = [];
    if (defined($options{get_param})) {
        $get_param = $options{get_param};
    }

    $self->settings();

    my $url_path = join_url_parts(
        $self->{option_results}->{api_path},
        $self->{option_results}->{api_version},
        $options{endpoint}
    );

    my $content;
    if ($options{method} eq "POST") {
        $content = $self->{http}->request(
            hostname        => $self->{option_results}->{hostname},
            method          => "POST",
            query_form_post => $options{body},
            url_path        => $url_path,
            unknown_status  => $self->{option_results}->{unknown_http_status},
            warning_status  => $self->{option_results}->{warning_http_status},
            critical_status => $self->{option_results}->{critical_http_status},
        );
    } elsif ($options{method} eq "GET") {
        $content = $self->{http}->request(
            hostname        => $self->{option_results}->{hostname},
            method          => "GET",
            url_path        => $url_path,
            get_param       => $get_param,
            unknown_status  => $self->{option_results}->{unknown_http_status},
            warning_status  => $self->{option_results}->{warning_http_status},
            critical_status => $self->{option_results}->{critical_http_status},
        );
    } else {
        return (0, undef, "HTTP method not supported");
    }

    if (!defined($content) || $content eq '') {
        return (0, undef, "API returns empty content");
    }

    return (1, $self->{http}->get_code(), $content);
}

1;

__END__

=head1 NAME

SMS Eagle REST API

=head1 SMS Eagle API OPTIONS

SMS Eagle REST API

=over 8

=item B<--hostname>

Address of the server that hosts the API.

=item B<--port>

Define the TCP port to use to reach the API (default: 443).

=item B<--proto>

Define the protocol to reach the API (default: 'https').

=item B<--api-version>

Define the API version (default: /v2).

=item B<--api-path>

Define the API path (default: /api).

=item B<--access-token>

SMSEagle API v2 user access token.

=item B<--timeout>

Define the timeout in seconds for HTTP requests (default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
