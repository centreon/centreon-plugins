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

package storage::ibm::flashsystem::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw(json_decode json_encode is_empty is_not_empty);
use Digest::SHA qw(sha256_hex);

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'            => { name => 'hostname', not_empty => 1 },
        'port:s'                => { name => 'port', default => 7443, type => 'port' },
        'proto:s'               => { name => 'proto', default => 'https', type => 'protocol_http' },
        'api-username:s'        => { name => 'api_username', not_empty => 1 },
        'api-password:s'        => { name => 'api_password', not_empty => 1 },
        'api-path:s'            => { name => 'api_path', default => '/rest/v1', not_empty => 1 },
        'timeout:s'             => { name => 'timeout', default => 30, numeric => 1 },
        'token-lifetime:s'      => { name => 'token_lifetime', default => 6600, numeric => 1 },
        'command-cache-ttl:s'   => { name => 'command_cache_ttl', default => 0, numeric => 1 },
        'rate-limit-max-wait:s' => { name => 'rate_limit_max_wait', default => 15, numeric => 1 }
    }) unless $options{noptions};
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache} = centreon::plugins::statefile->new(%options);
    $self->{response_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->{cache}->check_options(option_results => $self->{option_results});
    $self->{response_cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port};
}

sub settings {
    my ($self, %options) = @_;

    return if ($self->{settings_done});
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub response_message {
    my ($self, %options) = @_;

    return 'HTTP ' . $options{code} . (is_not_empty($options{content}) ? ' - ' . $options{content} : '');
}

# Waits before a retry on HTTP 429: Retry-After when the array sends it, a
# growing step otherwise. Returns 0 once the time budget of the check is spent.
sub rate_limit_wait {
    my ($self, %options) = @_;

    my $delay = $self->{http}->get_first_header(name => 'Retry-After');
    $delay = defined($delay) && $delay =~ /^\s*(\d+)\s*$/ ? $1 : $options{attempt} * 2;

    $self->{rate_limit_waited} //= 0;
    return 0 if ($self->{rate_limit_waited} + $delay > $self->{option_results}->{rate_limit_max_wait});

    sleep($delay);
    $self->{rate_limit_waited} += $delay;
    return 1;
}

sub authenticate {
    my ($self, %options) = @_;

    $self->settings();

    my $attempt = 0;
    while (1) {
        $attempt++;
        my $content = $self->{http}->request(
            method => 'POST',
            url_path => $self->{option_results}->{api_path} . '/auth',
            header => [
                'X-Auth-Username: ' . $self->{option_results}->{api_username},
                'X-Auth-Password: ' . $self->{option_results}->{api_password},
                'Accept: application/json'
            ],
            unknown_status => '',
            warning_status => '',
            critical_status => ''
        );

        my $code = $self->{http}->get_code();
        if ($code == 200) {
            my $decoded = json_decode($content, silence => 1);
            return $decoded->{token} if (ref($decoded) eq 'HASH' && is_not_empty($decoded->{token}));
        }

        my $message = $self->response_message(code => $code, content => $content);
        next if ($code == 429 && $self->rate_limit_wait(attempt => $attempt));

        # The caller re-reads the token cache, which another check may have
        # refreshed meanwhile.
        return (undef, $message) if ($code == 429);

        $self->{output}->option_exit(short_msg => 'Authentication failed: ' . $message);
    }
}

sub statefile_name {
    my ($self, %options) = @_;

    return 'ibm_flashsystem_api_'
        . sha256_hex($self->get_connection_info())
        . '_' . sha256_hex($self->{option_results}->{api_username});
}

sub cached_token {
    my ($self, %options) = @_;

    return undef if ($self->{cache}->read(statefile => $self->statefile_name()) == 0);

    my $token = $self->{cache}->get(name => 'token');
    my $expires_on = $self->{cache}->get(name => 'expires_on');

    return undef if (!defined($token) || !defined($expires_on));
    return undef if (time() >= $expires_on);

    $self->{token} = $token;
    return $token;
}

sub get_token {
    my ($self, %options) = @_;

    # After a 401/403, the token just rejected must not be picked up again
    # from the cache.
    my $rejected = $options{force} ? $self->{token} : undef;

    my $cached = $self->cached_token();
    return $cached if (!$options{force} && defined($cached));

    my ($token, $throttle_message) = $self->authenticate();

    if (!defined($token)) {
        my $refreshed = $self->cached_token();
        return $refreshed
            if (defined($refreshed) && (!defined($rejected) || $refreshed ne $rejected));

        $self->{output}->option_exit(
            short_msg => 'Authentication failed: ' . $throttle_message
                . ' The array is rate-limiting authentications and no other check has'
                . ' refreshed the cached token. Raising --token-lifetime spaces these out.'
        );
    }

    $self->{cache}->write(data => {
        token => $token,
        expires_on => time() + $self->{option_results}->{token_lifetime}
    });
    $self->{token} = $token;
    return $token;
}

sub response_cache_name {
    my ($self, %options) = @_;

    return 'ibm_flashsystem_api_rsp_' . sha256_hex($self->get_connection_info())
        . '_' . sha256_hex($self->{option_results}->{api_username} . '|' . $options{key});
}

sub cached_response {
    my ($self, %options) = @_;

    return undef if ($self->{response_cache}->read(statefile => $self->response_cache_name(key => $options{key})) == 0);

    my $stamp = $self->{response_cache}->get(name => 'stamp');
    my $response = $self->{response_cache}->get(name => 'response');
    return undef if (!defined($stamp) || $stamp !~ /^\d+$/ || ref($response) ne 'ARRAY');
    return undef if (time() - $stamp > $options{max_age});
    return $response;
}

sub store_response {
    my ($self, %options) = @_;

    # read() sets the file name used by write().
    $self->{response_cache}->read(statefile => $self->response_cache_name(key => $options{key}));
    $self->{response_cache}->write(data => { stamp => time(), response => $options{response} });
}

# Always returns an array reference: the API answers with a single object for
# some commands (lssystem) and with an array for others.
# With optional => 1, a 404 (command unknown to this firmware) returns undef;
# any other error ends the check.
sub request {
    my ($self, %options) = @_;

    my $payload = defined($options{payload}) ? $options{payload} : {};
    my $cache_ttl = $self->{option_results}->{command_cache_ttl};
    my $body = json_encode($payload, output => $self->{output});
    # json_encode is canonical: the same payload always gives the same key.
    my $cache_key = $options{command} . '|' . $body;

    if ($cache_ttl > 0) {
        my $cached = $self->cached_response(key => $cache_key, max_age => $cache_ttl);
        return $cached if (defined($cached));
    }

    my $token = $self->get_token();
    $self->settings();

    my ($attempt, $reauthenticated) = (0, 0);
    while (1) {
        $attempt++;
        my $content = $self->{http}->request(
            method => 'POST',
            url_path => $self->{option_results}->{api_path} . '/' . $options{command},
            header => [
                'X-Auth-Token: ' . $token,
                'Content-Type: application/json',
                'Accept: application/json'
            ],
            query_form_post => $body,
            unknown_status => '',
            warning_status => '',
            critical_status => ''
        );

        my $code = $self->{http}->get_code();

        # Session expired or invalidated on the array side: this recovery is
        # what allows a long --token-lifetime.
        if (($code == 401 || $code == 403) && !$reauthenticated) {
            $reauthenticated = 1;
            $token = $self->get_token(force => 1);
            next;
        }

        next if ($code == 429 && $self->rate_limit_wait(attempt => $attempt));

        if ($code == 429 && $cache_ttl > 0) {
            my $stale = $self->cached_response(key => $cache_key, max_age => 900);
            if (defined($stale)) {
                $self->{output}->output_add(
                    long_msg => "HTTP 429 on '" . $options{command} . "': served the cached response instead."
                );
                return $stale;
            }
        }

        return undef if ($code == 404 && $options{optional});

        $self->{output}->option_exit(
            short_msg => "API command '" . $options{command} . "' failed: "
                . $self->response_message(code => $code, content => $content)
        ) if ($code != 200);

        my $decoded = json_decode($content, silence => 1);
        $self->{output}->option_exit(short_msg => "Cannot decode API response for command '" . $options{command} . "'")
            if (!defined($decoded));

        my $result = ref($decoded) eq 'ARRAY' ? $decoded : [ $decoded ];
        $self->store_response(key => $cache_key, response => $result) if ($cache_ttl > 0);
        return $result;
    }
}

# Commands missing from some firmwares or models (lspartition only exists
# since 8.7) give an empty list instead of failing the check.
sub request_optional {
    my ($self, %options) = @_;

    my $result = $self->request(%options, optional => 1);
    return defined($result) ? $result : [];
}

# Capacities come as unit-suffixed strings ("310.99TB"). Returns undef when
# the value is missing, so that a mode can tell zero from no information.
sub size_to_bytes {
    my ($self, %options) = @_;

    my $value = $options{value};
    return undef if (is_empty($value));
    return undef if ($value !~ /^\s*([0-9]+(?:\.[0-9]+)?)\s*([KMGTPE]?)B?\s*$/i);

    my ($number, $unit) = ($1, uc($2));
    my %factor = ('' => 1, K => 1024, M => 1024**2, G => 1024**3,
                  T => 1024**4, P => 1024**5, E => 1024**6);

    return $number * $factor{$unit};
}

# Used by the system-status mode only, until its rewrite.
sub reachability {
    my ($self, %options) = @_;

    $self->settings();

    my $content = $self->{http}->request(
        method => 'POST',
        url_path => $self->{option_results}->{api_path} . '/auth',
        header => [
            'X-Auth-Username: ' . $self->{option_results}->{api_username},
            'X-Auth-Password: ' . $self->{option_results}->{api_password},
            'Accept: application/json'
        ],
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    my $code = $self->{http}->get_code();
    return ('ok', 'API responded') if ($code == 200);

    my $text = defined($content) ? $content : '';
    return ('unreachable', $text)
        if ($text =~ /can'?t connect|connection refused|no route to host|timeout|timed out/i);

    return ('degraded', $self->response_message(code => $code, content => $text));
}

1;

__END__

=head1 NAME

IBM Storage Virtualize REST API

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Management IP address or hostname of the system.

=item B<--port>

API port (default: 7443).

=item B<--proto>

Protocol (default: https).

=item B<--api-username>

Array account used to authenticate. The B<Monitor> role is sufficient and
recommended: it grants read-only access to the information commands.

=item B<--api-password>

Password of that account. Storage Virtualize has no API key: the credentials
are exchanged for a session token.

=item B<--api-path>

API prefix (default: C</rest/v1>). Set it to C</rest> for older firmware
versions that do not serve C</rest/v1>.

=item B<--token-lifetime>

Seconds a cached session token is reused (default: 6600, just under the array's
two-hour cap on an active session).

Keep it long. The array rate-limits authentications and answers B<429 Too Many
Requests> when pressed, whereas an expired token costs nothing: the plugin
re-authenticates by itself when a command comes back 401 or 403. Expiring the
token early protects against nothing and spends an authentication.

=item B<--command-cache-ttl>

Seconds a command B<response> is reused across checks of the same array
(default: 0, disabled; 55 is a good value when several services read the same
array).

The array also rate-limits commands. Splitting the monitoring into
single-purpose services multiplies plugin runs that read the B<same> C<ls*>
commands within the same minute, the first check of the cycle fills the
cache, the others read it, and the burst disappears without changing the
check cadence. Every command is a read, so caching is semantically safe; the
worst case is a detection delayed by under a minute on a five-minute cadence.
When a command still gets a 429 after the retries, the last response is served
if it is less than fifteen minutes old, rather than turning the check UNKNOWN.

The token is cached per array and per account, so every check of the same
system shares it. If authentications look far too frequent, check that the
cache directory (C<--statefile-dir>, C</var/lib/centreon/centplugins> by
default) is writable by the account running the checks.

=item B<--rate-limit-max-wait>

Maximum number of seconds a check waits in total before retrying requests the
array answered with B<429 Too Many Requests> (default: 15). The delay given by
the C<Retry-After> header is used when present. Keep the value well under the
check timeout of the poller. Set it to 0 to never retry.

=item B<--timeout>

HTTP timeout in seconds (default: 30).

=back

=cut
