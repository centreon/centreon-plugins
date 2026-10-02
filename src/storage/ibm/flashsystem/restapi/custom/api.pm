#
# Copyright 2026 Centreon (http://www.centreon.com/)
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
# Authors : Valentin MAROT <contact@valentin-marot.fr>
#

#
# Custom mode: talks to the Storage Virtualize REST API.
#
# Three traits of this API drive the design:
#   1. Every command is a POST, including the 'ls*' reads.
#   2. The prefix is /rest/v1 since 8.1.3, /rest before: it is auto-detected.
#   3. A session lasts 2 h active or 30 min idle, then answers 403. The token
#      is therefore cached on the poller and re-obtained on the fly when the
#      array rejects it.
#

package storage::ibm::flashsystem::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.");
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s'          => { name => 'hostname' },
            'port:s'              => { name => 'port', default => 7443, port => 1 },
            'proto:s'             => { name => 'proto', default => 'https', protocol_http => 1 },
            'api-username:s'      => { name => 'api_username' },
            'api-password:s'      => { name => 'api_password' },
            'api-path:s'          => { name => 'api_path' },
            'timeout:s'           => { name => 'timeout', default => 30, numeric => 1 },
            'token-lifetime:s'    => { name => 'token_lifetime', default => 6600, numeric => 1 },
            'command-cache-ttl:s' => { name => 'command_cache_ttl', default => 0, numeric => 1 }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);
    $self->{response_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    # Defaults and validations are declared with the options: nothing to
    # re-check here.
    $self->{hostname}     = $self->{option_results}->{hostname};
    $self->{port}         = $self->{option_results}->{port};
    $self->{proto}        = $self->{option_results}->{proto};
    $self->{timeout}      = $self->{option_results}->{timeout};
    $self->{api_username} = $self->{option_results}->{api_username};
    $self->{api_password} = $self->{option_results}->{api_password};
    $self->{api_path}     = $self->{option_results}->{api_path};
    # How long a token is reused. It has to be LONG: the array rate-limits
    # authentications and answers 429 when pushed, whereas an expired token
    # recovers by itself through the retry on 401/403. Expiring the token
    # early protects against nothing and costs an authentication. 6600 s
    # stays under the 2 h cap on an active session.
    $self->{token_lifetime} = $self->{option_results}->{token_lifetime};
    # How long a command response is reused. Disabled by default; 55 s is a
    # good value when several single-purpose services read the same array:
    # enough to absorb the burst of checks starting within the same minute,
    # short against a 5 min cadence - the worst detection delay stays under
    # a minute.
    $self->{command_cache_ttl} = $self->{option_results}->{command_cache_ttl};

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->option_exit(short_msg => 'Need to specify --hostname option.');
    }
    if (!defined($self->{api_username}) || $self->{api_username} eq '') {
        $self->{output}->option_exit(short_msg => 'Need to specify --api-username option.');
    }
    if (!defined($self->{api_password}) || $self->{api_password} eq '') {
        $self->{output}->option_exit(short_msg => 'Need to specify --api-password option.');
    }

    $self->{cache}->check_options(option_results => $self->{option_results});
    $self->{response_cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{hostname} . ':' . $self->{port};
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port}     = $self->{port};
    $self->{option_results}->{proto}    = $self->{proto};
    $self->{option_results}->{timeout}  = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

# The prefixes to try, in order. --api-path pins the choice when detection is
# not wanted (one more array in a known fleet, a known firmware).
sub api_paths {
    my ($self, %options) = @_;

    return ($self->{api_path}) if (defined($self->{api_path}) && $self->{api_path} ne '');
    return ('/rest/v1', '/rest');
}

sub decode_response {
    my ($self, %options) = @_;

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($options{content});
    };
    if ($@) {
        return undef;
    }
    return $decoded;
}

# Authentication: POST <prefix>/auth with the credentials in headers. The
# answer carries a token (a JWT on recent firmwares, a hex string before). On
# failure the body carries the IBM code (CMMVCxxxxE): it is passed through as
# is, since it is what tells a wrong password from an account with no role.
sub authenticate {
    my ($self, %options) = @_;

    $self->settings();

    my $last_message;

    # The array rate-limits authentications and answers 429. A few checks
    # expiring at the same time are enough to trigger it, hence a growing
    # back-off before giving up. The total stays under a Centreon check
    # timeout.
    foreach my $attempt (1 .. 3) {
        my $throttled = 0;

        foreach my $path ($self->api_paths()) {
            my $content = $self->{http}->request(
                method => 'POST',
                url_path => $path . '/auth',
                header => [
                    'X-Auth-Username: ' . $self->{api_username},
                    'X-Auth-Password: ' . $self->{api_password},
                    'Accept: application/json'
                ],
                unknown_status => '',
                warning_status => '',
                critical_status => ''
            );

            my $code = $self->{http}->get_code();
            if ($code == 200) {
                my $decoded = $self->decode_response(content => $content);
                if (defined($decoded) && defined($decoded->{token}) && $decoded->{token} ne '') {
                    return ($decoded->{token}, $path);
                }
            }

            $last_message = 'HTTP ' . $code . (defined($content) && $content ne '' ? ' - ' . $content : '');

            # No point trying the other prefix: the rate is being refused,
            # not the URL.
            if ($code == 429) {
                $throttled = 1;
                last;
            }
        }

        last if (!$throttled || $attempt == 3);
        sleep($attempt * 2);
    }

    # A 429 does not exit: the caller re-reads the cache, which a neighbouring
    # check may have refreshed while we waited.
    return (undef, undef, $last_message) if (defined($last_message) && $last_message =~ /^HTTP 429/);

    $self->{output}->add_option_msg(
        short_msg => 'Authentication failed: ' . (defined($last_message) ? $last_message : 'no response')
    );
    $self->{output}->option_exit();
}

# Cache file name: one entry per array and per account, shared by every check
# of that array.
sub statefile_name {
    my ($self, %options) = @_;

    return 'ibm_flashsystem_api_'
        . md5_hex($self->{hostname} . ':' . $self->{port})
        . '_' . md5_hex($self->{api_username});
}

# Re-reads the cache and returns the token if still valid, undef otherwise.
sub cached_token {
    my ($self, %options) = @_;

    return undef if ($self->{cache}->read(statefile => $self->statefile_name()) == 0);

    my $token = $self->{cache}->get(name => 'token');
    my $path = $self->{cache}->get(name => 'api_path');
    my $expires_on = $self->{cache}->get(name => 'expires_on');

    return undef if (!defined($token) || !defined($path) || !defined($expires_on));
    return undef if (time() >= $expires_on);

    $self->{token} = $token;
    $self->{resolved_path} = $path;
    return $token;
}

# The token is shared by every check of the same array and account: without
# this cache each service would open its own session.
sub get_token {
    my ($self, %options) = @_;

    my $force = defined($options{force}) && $options{force} == 1;

    # The one token we must not pick up again: the one the array has just
    # rejected, when we are here because of a 401/403.
    my $rejected = $force ? $self->{token} : undef;

    # cached_token() reads the file, which also sets its name for writing.
    my $cached = $self->cached_token();
    return $cached if (!$force && defined($cached));

    my ($token, $path, $throttle_message) = $self->authenticate();

    # Authentication refused because of the rate. Every check of the same
    # array notices the token expiry at the same moment and rushes /auth: by
    # the time we have waited, one of them has usually succeeded and written
    # the cache. Re-read it rather than insist - unless it hands back the very
    # token we just got rejected.
    if (!defined($token)) {
        my $refreshed = $self->cached_token();
        if (defined($refreshed) && (!defined($rejected) || $refreshed ne $rejected)) {
            return $refreshed;
        }

        $self->{output}->add_option_msg(
            short_msg => 'Authentication failed: ' . $throttle_message
                . ' The array is rate-limiting authentications and no other check has'
                . ' refreshed the cached token. Raising --token-lifetime spaces these out.'
        );
        $self->{output}->option_exit();
    }

    $self->{cache}->write(data => {
        token => $token,
        api_path => $path,
        expires_on => time() + $self->{token_lifetime}
    });
    $self->{token} = $token;
    $self->{resolved_path} = $path;
    return $token;
}

# RESPONSE cache, shared between the checks of one array through the poller
# state directory - the same principle as the token cache.
#
# Why: splitting the monitoring into single-purpose services multiplies plugin
# runs, and several services re-read the SAME commands within the same minute
# - three services carved out of the performance mode each re-read
# lssystemstats, two per-partition replication services redo the same four
# calls, and lssystem is read by half the modes. The array rate-limits and
# answers 429. The first check of the cycle fills the cache, the following
# ones read it: the burst disappears without changing the monitoring cadence.
# Every command is an ls* read, so caching is semantically safe.

sub response_cache_name {
    my ($self, %options) = @_;

    return 'ibm_flashsystem_api_rsp_' . md5_hex($self->{hostname} . ':' . $self->{port})
        . '_' . md5_hex($self->{api_username} . '|' . $options{key});
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

    # read() first: it is what sets the file name write() uses.
    $self->{response_cache}->read(statefile => $self->response_cache_name(key => $options{key}));
    $self->{response_cache}->write(data => { stamp => time(), response => $options{response} });
}

# request: runs a CLI command through the API.
#
# $options{command}  command name, for instance 'lsvdisk'
# $options{payload}  parameters, for instance { filtervalue => 'fixed=no' }
#
# Always returns an array reference: the API answers sometimes with a single
# object (lssystem), sometimes with an array. Modes never have to test which.
# With optional => 1 an HTTP error or an undecodable answer returns undef
# instead of ending the check: option_exit() leaves the process, an eval()
# around the call does not catch it - request_optional relies on this flag.
sub request {
    my ($self, %options) = @_;

    my $payload = defined($options{payload}) ? $options{payload} : {};
    # canonical: the same payload always gives the same key, whatever the
    # internal hash order.
    my $cache_key = $options{command} . '|' . JSON::XS->new->utf8->canonical->encode($payload);

    if ($self->{command_cache_ttl} > 0) {
        my $cached = $self->cached_response(key => $cache_key, max_age => $self->{command_cache_ttl});
        return $cached if (defined($cached));
    }

    my $token = $self->get_token();

    my $attempt = 0;
    while (1) {
        $attempt++;
        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST',
            url_path => $self->{resolved_path} . '/' . $options{command},
            header => [
                'X-Auth-Token: ' . $token,
                'Content-Type: application/json',
                'Accept: application/json'
            ],
            query_form_post => JSON::XS->new->utf8->encode($payload),
            unknown_status => '',
            warning_status => '',
            critical_status => ''
        );

        my $code = $self->{http}->get_code();

        # 401 / 403: session expired or invalidated on the array side.
        # Re-authenticate once, then give up rather than loop. This recovery
        # is what allows keeping a token cached for long instead of renewing
        # it as a precaution.
        if (($code == 401 || $code == 403) && $attempt == 1) {
            $token = $self->get_token(force => 1);
            next;
        }

        # 429 on a command: the array rate-limits requests. Back off with a
        # growing step before giving up.
        if ($code == 429 && $attempt <= 3) {
            sleep($attempt * 3);
            next;
        }

        # Still throttled after the retries: rather than turning the check
        # UNKNOWN, serve the last known response if it is under fifteen
        # minutes old. A slightly stale state beats a hole in the monitoring
        # during a passing API saturation.
        if ($code == 429 && $self->{command_cache_ttl} > 0) {
            my $stale = $self->cached_response(key => $cache_key, max_age => 900);
            if (defined($stale)) {
                $self->{output}->output_add(
                    long_msg => "HTTP 429 on '" . $options{command} . "': served the cached response instead."
                );
                return $stale;
            }
        }

        if ($code != 200) {

            return undef if ($options{optional});
            $self->{output}->add_option_msg(
                short_msg => "API command '" . $options{command} . "' failed (HTTP " . $code . ")"
                    . (defined($content) && $content ne '' ? ': ' . $content : '')
            );
            $self->{output}->option_exit();
        }

        my $decoded = $self->decode_response(content => $content);
        if (!defined($decoded)) {
            return undef if ($options{optional});
            $self->{output}->option_exit(short_msg => "Cannot decode API response for command '" . $options{command} . "'");
        }

        my $result = ref($decoded) eq 'ARRAY' ? $decoded : [ $decoded ];
        $self->store_response(key => $cache_key, response => $result)
            if ($self->{command_cache_ttl} > 0);
        return $result;
    }
}

# The API returns capacities as unit-suffixed strings: "310.99TB", "0.00MB",
# sometimes "1.25PB". Thresholds and perfdata want bytes. Returns undef when
# the value is missing or unusable, so a mode can tell "zero" from "no
# information".
sub size_to_bytes {
    my ($self, %options) = @_;

    my $value = $options{value};
    return undef if (!defined($value) || $value eq '');
    return undef if ($value !~ /^\s*([0-9]+(?:\.[0-9]+)?)\s*([KMGTPE]?)B?\s*$/i);

    my ($number, $unit) = ($1, uc($2));
    my %factor = ('' => 1, K => 1024, M => 1024**2, G => 1024**3,
                  T => 1024**4, P => 1024**5, E => 1024**6);

    return $number * $factor{$unit};
}

# Array reachability, for the sole use of the host check.
#
# "Did the API answer" is not enough: a rejected token, a 429 or a broken
# certificate are monitoring problems, not dead arrays. Mixing them up would
# take the host DOWN and make ALL its services UNREACHABLE - losing the
# monitoring right when it matters most.
#
# Returns one of three values:
#   'unreachable' the device does not answer at all;
#   'degraded'    it answers but the API refuses to serve us;
#   'ok'          the API answers normally.
sub reachability {
    my ($self, %options) = @_;

    $self->settings();

    my $content = $self->{http}->request(
        method => 'POST',
        url_path => ($self->api_paths())[0] . '/auth',
        header => [
            'X-Auth-Username: ' . $self->{api_username},
            'X-Auth-Password: ' . $self->{api_password},
            'Accept: application/json'
        ],
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    my $code = $self->{http}->get_code();
    return ('ok', 'API responded') if ($code == 200);

    # The HTTP library returns a synthetic 500 when the connection itself
    # failed: the text is what tells "nobody at the other end" from an
    # application answer.
    my $text = defined($content) ? $content : '';
    return ('unreachable', $text)
        if ($text =~ /can'?t connect|connection refused|no route to host|timeout|timed out/i);

    return ('degraded', 'HTTP ' . $code . ($text ne '' ? ' - ' . $text : ''));
}

# Some commands do not exist on every firmware or model: lspartition only
# appears in 8.7, lsrcrelationship disappears from setups that only use
# policy-based replication. A generic mode must be able to ask without
# knowing, hence this tolerant variant that returns an empty list rather
# than failing the check.
sub request_optional {
    my ($self, %options) = @_;

    my $result;
    eval {
        local $SIG{__DIE__};
        $result = $self->request(%options, optional => 1);
    };
    return [] if ($@ || !defined($result));
    return $result;
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

Pin the API prefix instead of detecting it. Storage Virtualize 8.1.3 and later
serve C</rest/v1>; earlier releases serve C</rest>. Left empty, both are tried
in that order.

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
commands within the same minute — the first check of the cycle fills the
cache, the others read it, and the burst disappears without changing the
check cadence. Every command is a read, so caching is semantically safe; the
worst case is a detection delayed by under a minute on a five-minute cadence.
When a command still gets a 429 after the retries, the last response is served
if it is less than fifteen minutes old, rather than turning the check UNKNOWN.

The token is cached per array and per account, so every check of the same
system shares it. If authentications look far too frequent, check that the
cache directory (C<--statefile-dir>, C</var/lib/centreon/centplugins> by
default) is writable by the account running the checks.

=item B<--timeout>

HTTP timeout in seconds (default: 30).

=back

=cut
