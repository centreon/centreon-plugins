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
use centreon::plugins::misc qw(json_decode json_encode is_not_empty);
use Digest::SHA qw(sha256_hex);

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{noptions})) {
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
        });
    }
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

sub rate_limit_wait {
    my ($self, %options) = @_;

    my $delay = $self->{http}->get_first_header(name => 'Retry-After');
    $delay = (defined($delay) && $delay =~ /^\s*(\d+)\s*$/) ? $1 : $options{attempt} * 2;
    $delay = 1 if ($delay < 1);

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

    $self->{response_cache}->read(statefile => $self->response_cache_name(key => $options{key}));
    $self->{response_cache}->write(data => { stamp => time(), response => $options{response} });
}

sub request {
    my ($self, %options) = @_;

    my $payload = $options{payload} // {};
    my $cache_ttl = $self->{option_results}->{command_cache_ttl};
    my $body = json_encode($payload, output => $self->{output});
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

        if (($code == 401 || $code == 403) && !$reauthenticated) {
            $reauthenticated = 1;
            $token = $self->get_token(force => 1);
            next;
        }

        next if ($code == 429 && $self->rate_limit_wait(attempt => $attempt));

        return undef if ($code == 404 && $options{optional});

        $self->{output}->option_exit(
            short_msg => "API command '" . $options{command} . "' failed: "
                . $self->response_message(code => $code, content => $content)
        ) if ($code != 200);

        my $decoded = json_decode(
            $content,
            output => $self->{output},
            errstr => "Cannot decode API response for command '" . $options{command} . "'"
        );

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
    return $result // [];
}

1;

__END__

=head1 NAME

IBM Storage Virtualize REST API

=head1 SYNOPSIS

IBM Storage Virtualize REST API custom mode

=head1 REST API OPTIONS

IBM Storage Virtualize REST API

=over 8

=item B<--hostname>

Define the name or the address of the system.

=item B<--port>

Define the port to connect to (default: 7443).

=item B<--proto>

Define the protocol to reach the API (default: 'https').

=item B<--api-username>

Define the username of an account with the C<Monitor> role.

=item B<--api-password>

Define the password of the account.

=item B<--api-path>

Define the API path prefix (default: C</rest/v1>).
Set it to C</rest> for older firmware versions that do not serve C</rest/v1>.

=item B<--timeout>

Define the timeout in seconds (default: 30).

=item B<--token-lifetime>

Define the number of seconds a session token is cached and shared by the checks of the same system and account (default: 6600, under the two-hour limit of an active session).
An expired or rejected token is renewed automatically.

=item B<--command-cache-ttl>

Define the number of seconds a command response is cached and shared by the checks of the same system (default: 0, disabled).

=item B<--rate-limit-max-wait>

Define the maximum number of seconds a check waits in total before retrying the requests answered with HTTP 429 (default: 15).
The C<Retry-After> header is used when present. Set it to 0 to disable the retries.

=back

=head1 DESCRIPTION

B<custom>.

=cut
