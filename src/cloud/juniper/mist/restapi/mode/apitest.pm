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

package cloud::juniper::mist::restapi::mode::apitest;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw(json_decode);
use Time::HiRes;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'api', type => COUNTER_TYPE_GLOBAL }
    ];

    $self->{maps_counters}->{api} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            # Since Mist publishes no machine-readable status page, this mode
            # carries the diagnostic burden: it separates "the cloud is
            # unreachable" from "our token is invalid/revoked", which call for
            # very different on-call responses. It also surfaces token expiry
            # risk (unused Mist org tokens are revoked after 90 days).
            critical_default => '%{status} =~ /auth_failed|unreachable|server_error|error/',
            warning_default => '%{status} =~ /rate_limited/',
            set => {
                key_values => [ { name => 'status' }, { name => 'http_code' }, { name => 'message' } ],
                output_template => '%{message}',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'response-time', nlabel => 'mist.api.response.time.seconds',
            set => {
                key_values => [ { name => 'response_time' } ],
                output_template => 'response time: %.3fs',
                perfdatas => [
                    { template => '%.3f', unit => 's', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $started = Time::HiRes::time();

    # Ask the custom layer for the raw outcome (no_exit_on_error) with the HTTP
    # status thresholds disabled, so we build the verdict ourselves.
    my $response = $options{custom}->request_api(
        endpoint => '/api/v1/self',
        no_exit_on_error => 1,
        unknown_status => '', warning_status => '', critical_status => ''
    );

    my $elapsed = sprintf('%.3f', Time::HiRes::time() - $started);
    my $code = $response->{code} // 0;
    my $http_message = $response->{message} // '';

    my ($status, $message);
    if ($code >= 200 && $code < 300) {
        my $decoded = json_decode($response->{content}, output => $self->{output});
        my @privileges;
        if (ref($decoded->{privileges}) eq 'ARRAY') {
            foreach my $privilege (@{$decoded->{privileges}}) {
                push @privileges, ($privilege->{scope} // 'unknown') . '/' . ($privilege->{role} // 'unknown');
            }
        }
        my $identity = $decoded->{email} // $decoded->{name} // 'token';
        my $detail = @privileges ? ' (' . join(', ', sort @privileges) . ')' : '';
        $status = 'ok';
        $message = "Mist API reachable, credentials valid for '$identity'$detail";
    } elsif ($code == 401 || $code == 403) {
        $status = 'auth_failed';
        $message = "Mist API reachable but authentication rejected (HTTP $code) - token invalid, revoked or lacking privileges";
    } elsif ($code == 429) {
        $status = 'rate_limited';
        $message = "Mist API rate limit reached (HTTP 429) - polling too frequent or quota shared with another consumer";
    } elsif ($code == 0
        || $http_message =~ /can't connect|connection (?:refused|reset|timed out)|timeout|could not connect|no route to host|network is unreachable|bad hostname|name or service not known/i) {
        # The LWP backend maps connection-level failures to HTTP 500 with a
        # "Can't connect ..." message, so we detect them by message rather than
        # code to tell a genuine cloud outage from a Mist server-side 5xx.
        $status = 'unreachable';
        $message = "Mist API unreachable: " . ($http_message ne '' ? $http_message : 'connection failed');
    } elsif ($code >= 500) {
        $status = 'server_error';
        $message = "Mist API server error (HTTP $code) - likely a cloud-side incident";
    } else {
        $status = 'error';
        $message = "Mist API error (HTTP $code)";
    }

    $self->{api} = {
        status => $status,
        http_code => $code,
        message => $message,
        response_time => $elapsed
    };
}

1;

__END__

=head1 MODE

Test reachability of the Juniper Mist API and the validity of the organization
token, by calling the C</self> endpoint. This mode is the availability sentinel
for the plugin: Mist does not publish a machine-readable status page, so it
distinguishes a cloud outage from an invalid/revoked token.

Default verdicts:

=over 4

=item * connection failure / timeout -> CRITICAL (probable cloud incident)

=item * HTTP 401 / 403 -> CRITICAL (token invalid, revoked or lacking privileges)

=item * HTTP 429 -> WARNING (quota exceeded)

=item * HTTP 5xx -> CRITICAL (Mist server error)

=item * HTTP 2xx -> OK (identity and privileges reported)

=back

=over 8

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default:
'%{status} =~ /rate_limited/'). Variables: %{status}, %{http_code}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default:
'%{status} =~ /auth_failed|unreachable|server_error|error/').

=item B<--warning-response-time> B<--critical-response-time>

Threshold on the API response time in seconds (no default).

=back

=cut
