#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::juniper::mist::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::misc qw(json_decode);

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        if (!defined($options{options}));

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s'             => { name => 'hostname', default => 'api.eu.mist.com' },
            'port:s'                 => { name => 'port', type => 'port', default => 443 },
            'proto:s'                => { name => 'proto', type => 'protocol_http', default => 'https' },
            'api-token:s'            => { name => 'api_token' },
            'org-id:s'               => { name => 'org_id' },
            'timeout:s'              => { name => 'timeout', type => 'numeric', default => 30 },
            'max-pages:s'            => { name => 'max_pages', type => 'numeric', default => 30 },
            'unknown-http-status:s'  => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  => { name => 'warning_http_status', default => '' },
            'critical-http-status:s' => { name => 'critical_http_status', default => '' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{$_} = $self->{option_results}->{$_}
        foreach (qw/hostname port proto api_token org_id timeout max_pages
                    unknown_http_status warning_http_status critical_http_status/);

    $self->{output}->option_exit(short_msg => "Need to specify --api-token option.")
        if (!defined($self->{api_token}) || $self->{api_token} eq '');
    $self->{output}->option_exit(short_msg => "Need to specify --org-id option.")
        if (!defined($self->{org_id}) || $self->{org_id} eq '');

    return 0;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
}

sub get_org_id {
    my ($self, %options) = @_;

    return $self->{org_id};
}

sub settings {
    my ($self, %options) = @_;

    return if ($self->{settings_done});
    # The Mist organization token is a static, read-only API key sent as a
    # 'Token' (not 'Bearer') Authorization header. There is no OAuth flow and
    # therefore no token to cache or renew.
    $self->{http}->add_header(key => 'Authorization', value => 'Token ' . $self->{api_token});
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{option_results}->{$_} = $self->{$_}
        foreach (qw/hostname port proto timeout/);
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    # The --unknown/warning/critical-http-status options are passed to the http
    # layer for familiarity with the rest of the collection, but data modes
    # deliberately exit UNKNOWN on any non-2xx via _http_error_exit below, with a
    # friendly mapped message (401/403 token, 429 quota, 5xx). Deriving a
    # WARNING/CRITICAL verdict from the HTTP code is the job of the api-test
    # mode, which overrides these thresholds with empty ones and passes
    # no_exit_on_error to build its own verdict.
    my $content = $self->{http}->request(
        url_path        => $options{endpoint},
        get_param       => $options{get_param},
        unknown_status  => defined($options{unknown_status}) ? $options{unknown_status} : $self->{unknown_http_status},
        warning_status  => defined($options{warning_status}) ? $options{warning_status} : $self->{warning_http_status},
        critical_status => defined($options{critical_status}) ? $options{critical_status} : $self->{critical_http_status}
    );
    my $code = $self->{http}->get_code();

    # api-test wants the raw outcome to build its own verdict.
    return { code => $code, message => $self->{http}->get_message(), content => $content }
        if ($options{no_exit_on_error});

    $self->_http_error_exit(code => $code, endpoint => $options{endpoint})
        if ($code < 200 || $code >= 300);

    return json_decode($content, output => $self->{output});
}

# Pagination for endpoints returning a bare JSON array, driven by the 'page'
# and 'limit' parameters. Used by /stats/devices, which - unlike the search
# endpoints - returns an unwrapped array with no 'results' envelope.
sub request_api_paginated {
    my ($self, %options) = @_;

    my $limit = $options{limit} // 1000;
    my $max_pages = $options{max_pages} // $self->{max_pages};
    my @results;

    for (my $page = 1; $page <= $max_pages; $page++) {
        my @get_param = ('limit=' . $limit, 'page=' . $page);
        push @get_param, @{$options{get_param}} if (defined($options{get_param}));

        my $decoded = $self->request_api(
            endpoint  => $options{endpoint},
            get_param => \@get_param
        );

        last if (ref($decoded) ne 'ARRAY');
        push @results, @$decoded;
        last if (scalar(@$decoded) < $limit);
    }

    return \@results;
}

# Pagination for Mist "search" endpoints. These wrap results in an object and
# expose a 'next' field holding a ready-made path with a 'search_after' cursor.
# The classic page/limit pagination does NOT work on these endpoints.
sub request_api_search {
    my ($self, %options) = @_;

    my $limit = $options{limit} // 1000;
    my $max_pages = $options{max_pages} // $self->{max_pages};
    my @results;

    my $endpoint = $options{endpoint};
    my @get_param = ('limit=' . $limit);
    push @get_param, @{$options{get_param}} if (defined($options{get_param}));

    my $truncated = 0;

    for (my $page = 1; $page <= $max_pages; $page++) {
        my $decoded = $self->request_api(
            endpoint  => $endpoint,
            get_param => \@get_param
        );

        $self->{output}->option_exit(short_msg => "Unexpected response format from $options{endpoint}")
            if (ref($decoded) ne 'HASH' || ref($decoded->{results}) ne 'ARRAY');

        push @results, @{$decoded->{results}};

        if (!defined($decoded->{next}) || $decoded->{next} eq ''
            || scalar(@{$decoded->{results}}) < $limit) {
            $truncated = 0;
            last;
        }

        # 'next' is a path plus an already-encoded query string; split it so the
        # next call receives the same shape as the first one.
        my ($next_path, $next_query) = split(/\?/, $decoded->{next}, 2);
        $endpoint = $next_path;
        @get_param = defined($next_query) ? split(/&/, $next_query) : ();
        $truncated = 1;
    }

    return (\@results, $truncated);
}

sub _http_error_exit {
    my ($self, %options) = @_;

    my $code = $options{code};
    my $message = $self->{http}->get_message();

    if ($code == 401 || $code == 403) {
        $self->{output}->option_exit(short_msg => "Authentication failed (HTTP $code) - check API token validity and privileges.");
    } elsif ($code == 429) {
        $self->{output}->option_exit(short_msg => "Mist API rate limit exceeded (HTTP 429) - reduce check frequency.");
    }

    $self->{output}->option_exit(short_msg => "HTTP error [code: $code] [message: $message] on '$options{endpoint}'");
}

1;

__END__

=head1 NAME

Juniper Mist REST API

=head1 SYNOPSIS

Juniper Mist cloud REST API custom mode.

=head1 REST API OPTIONS

Juniper Mist REST API accessed with a read-only organization token.

Generate an organization API token from the Mist dashboard
(Organization > Settings > API Token) and pass it with C<--api-token>.

=over 8

=item B<--hostname>

Mist API regional endpoint (default: 'api.eu.mist.com').
Use 'api.mist.com' (Global 01), 'api.gc1.mist.com' (Global 03), etc. depending
on the region hosting your organization.

=item B<--port>

Port used (default: 443).

=item B<--proto>

Protocol to use: 'http' or 'https' (default: 'https').

=item B<--api-token>

Mist organization API token. Sent as the 'Authorization: Token <token>' header.

=item B<--org-id>

Mist organization UUID. Used to build the '/api/v1/orgs/<org-id>/...' paths.

=item B<--timeout>

HTTP request timeout in seconds (default: 30).

=item B<--max-pages>

Maximum number of pages to retrieve when paginating list/search endpoints
(default: 30). Safety bound against unbounded result sets.

=item B<--unknown-http-status>

Unknown threshold for the HTTP response code
(default: '%{http_code} < 200 or %{http_code} >= 300').

=item B<--warning-http-status>

Warning threshold for the HTTP response code.

=item B<--critical-http-status>

Critical threshold for the HTTP response code.

=back

=head1 MIST API CAVEATS

Verified against 'api.eu.mist.com':

=over 8

=item * The '/nac_clients/events/search' and '/nac_clients/events/count'
endpoints accept a 'site_id' query parameter but B<do not apply it>. The
response is identical with or without the filter, and even a non-existent site
UUID returns organization-wide data. Per-site NAC figures must therefore be
computed client-side from the 'site_id' field carried by each event.

=item * By contrast, '/alarms/search' and '/stats/devices' B<do> honour
'site_id' server-side, so those modes pass it straight through.

=item * Endpoint shapes are inconsistent: '/stats/devices' returns a bare JSON
array (page/limit pagination), while the '*/search' endpoints wrap results in a
'results' key and paginate through a 'next' field carrying a 'search_after'
cursor.

=back

=head1 DESCRIPTION

B<custom>.

=cut
