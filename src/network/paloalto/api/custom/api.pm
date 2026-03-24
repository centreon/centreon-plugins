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

package network::paloalto::api::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::constants qw(:values);
use XML::Simple;
use MIME::Base64 qw(encode_base64);
use URI::Escape qw(uri_escape);
use Digest::SHA qw(sha256_hex);
use centreon::plugins::misc qw(is_empty);

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    unless ($options{output}) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless $options{options};

    unless ($options{noptions}) {
        $options{options}->add_options(arguments => {
            'hostname:s'             => { name => 'hostname',             default => '' },
            'port:s'                 => { name => 'port',                 default => 443 },
            'proto:s'                => { name => 'proto',                default => 'https' },
            'auth-type:s'            => { name => 'auth_type',            default => 'api-key' },
            'api-key:s'              => { name => 'api_key',              default => '' },
            'username:s'             => { name => 'username',             default => '' },
            'password:s'             => { name => 'password',             default => '' },
            'timeout:s'              => { name => 'timeout',              default => 30 },
            'unknown-http-status:s'  => { name => 'unknown_http_status',  default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  => { name => 'warning_http_status',  default => '' },
            'critical-http-status:s' => { name => 'critical_http_status', default => '' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http}   = centreon::plugins::http->new(%options, default_backend => 'curl');
    $self->{cache}  = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname}             = $self->{option_results}->{hostname};
    $self->{port}                 = $self->{option_results}->{port};
    $self->{proto}                = $self->{option_results}->{proto};
    $self->{auth_type}            = $self->{option_results}->{auth_type};
    $self->{api_key}              = $self->{option_results}->{api_key};
    $self->{username}             = $self->{option_results}->{username};
    $self->{password}             = $self->{option_results}->{password};
    $self->{timeout}              = $self->{option_results}->{timeout};
    $self->{unknown_http_status}  = $self->{option_results}->{unknown_http_status};
    $self->{warning_http_status}  = $self->{option_results}->{warning_http_status};
    $self->{critical_http_status} = $self->{option_results}->{critical_http_status};

    $self->{output}->option_exit(short_msg => "Need to specify --hostname option.")
        if $self->{hostname} eq '';
    $self->{output}->option_exit(short_msg => "Unknown --auth-type value '$self->{auth_type}' (must be 'api-key' or 'basic').")
        if $self->{auth_type} !~ /^(?:api-key|basic)$/;
    $self->{output}->option_exit(short_msg => "With --auth-type=api-key: specify --api-key or --username/--password to auto-generate it.")
        if $self->{auth_type} eq 'api-key' && $self->{api_key} eq '' && $self->{username} eq '';

    $self->{output}->option_exit(short_msg => "Need to specify --username/--password options with --auth-type=basic.")
        if $self->{auth_type} eq 'basic' && ($self->{username} eq '' || $self->{password} eq '');

    $self->{cache}->check_options(option_results => $self->{option_results});

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

sub settings {
    my ($self, %options) = @_;

    return if $self->{settings_done};
    $self->{option_results}->{$_} = $self->{$_}
        foreach qw/hostname port proto timeout/;
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub generate_api_key {
    my ($self, %options) = @_;

    $self->{output}->output_add(long_msg => "Generating API key for user '$self->{username}'", debug => 1);

    my $content = $self->{http}->request(
        url_path        => '/api/',
        method          => 'POST',
        get_param       => ['type=keygen'],
        query_form_post => 'user=' . uri_escape($self->{username}) . '&password=' . uri_escape($self->{password}),
        header          => ['Content-Type: application/x-www-form-urlencoded'],
        unknown_status  => '',
        warning_status  => '',
        critical_status => ''
    );

    my $code = $self->{http}->get_code();
    $self->{output}->option_exit(short_msg => sprintf("API key generation failed [code: %s] [message: %s]", $code, $self->{http}->get_message()))
        if $code < 200 || $code >= 300;

    my $result = $self->_parse_xml($content);
    $self->{output}->option_exit(short_msg => "API key generation response does not contain a key.")
        if is_empty($result->{key});

    $self->{api_key} = $result->{key};
    $self->{cache}->write(data => {
        updated => time(),
        api_key => $self->{api_key}
    });
    $self->{output}->output_add(long_msg => "API key successfully generated and cached", debug => 1);
}

sub _load_api_key {
    my ($self) = @_;

    # Use api-key if it was explicitly provided
    return if $self->{api_key} ne '';

    my $cache_name = 'paloalto_api_' . sha256_hex($self->{hostname} . '_' . $self->{username});
    my $has_cache  = $self->{cache}->read(statefile => $cache_name);

    if ($has_cache != BUFFER_CREATION) {
        my $cached_key = $self->{cache}->get(name => 'api_key');
        unless (is_empty($cached_key)) {
            $self->{api_key} = $cached_key;
            $self->{output}->output_add(long_msg => "Using cached API key", debug => 1);
            return;
        }
    }

    $self->generate_api_key();
}

sub _build_auth_header {
    my ($self) = @_;

    return $self->{auth_type} eq 'api-key'
        ? 'X-PAN-KEY: ' . $self->{api_key}
        : 'Authorization: Basic ' . encode_base64($self->{username} . ':' . $self->{password}, '');
}

sub _http_request {
    my ($self, %options) = @_;

    return $self->{http}->request(
        url_path  => '/api/',
        get_param => [
            'type=' . $options{type},
            'cmd='  . $options{cmd}
        ],
        header => [
            $self->_build_auth_header(),
            'Accept: application/xml'
        ],
        unknown_status  => $options{unknown_status}  // '',
        warning_status  => $options{warning_status}  // '',
        critical_status => $options{critical_status} // ''
    );
}

sub _parse_xml {
    my ($self, $content, %options) = @_;

    $self->{output}->output_add(long_msg => "API response: $content", debug => 1);

    $self->{output}->option_exit( short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($content);

    $self->{output}->option_exit(short_msg => "Cannot find XML response in API reply.")
        unless $content =~ /(<response status=["'](.*?)["']>.*<\/response>)/ms;

    my ($xml, $status) = ($1, $2);
    $self->{output}->option_exit(short_msg => "API response status: $status")
        unless $status eq 'success';

    my $result;
    eval {
        $result = XMLin($xml, ForceArray => $options{ForceArray} // [], KeyAttr => []);
    };
    $self->{output}->option_exit(short_msg => "Cannot decode XML response: $@")
        if $@;

    return $result->{result};
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    $self->_load_api_key() if ($self->{auth_type} eq 'api-key');

    # First attempt without status checking so we can intercept 401/403
    my $content = $self->_http_request(%options);
    my $code    = $self->{http}->get_code();

    if ($self->{auth_type} eq 'api-key' && $code =~ /^(?:401|403)$/) {
        $self->{output}->output_add(long_msg => "Got HTTP $code, regenerating API key and retrying", debug => 1);
        $self->generate_api_key();

        # Second attempt with status checking enabled
        $content = $self->_http_request(
            %options,
            unknown_status  => $self->{unknown_http_status},
            warning_status  => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    } elsif ($code < 200 || $code >= 300) {
        $self->{output}->option_exit(short_msg => sprintf("HTTP error [code: %s] [message: %s]", $code, $self->{http}->get_message()));
    }

    return $self->_parse_xml($content, %options);
}

1;

__END__

=head1 NAME

Palo Alto XML API

=head1 API OPTIONS

=over 8

=item B<--hostname>

Hostname or IP address of the Palo Alto device.

=item B<--port>

Port used (default: 443).

=item B<--proto>

Protocol to use: http or https (default: https).

=item B<--auth-type>

Authentication type: C<api-key> (default) or C<basic>.

=item B<--api-key>

PAN-OS API key (sent as X-PAN-KEY header). Used with --auth-type=api-key.
If omitted, the key is auto-generated from --username/--password via the C<keygen API>
and cached locally. A 401 or 403 response also triggers automatic key regeneration.

=item B<--username>

Username. Required with --auth-type=basic.
Also used with --auth-type=api-key to auto-generate or regenerate the API key.

=item B<--password>

Password.

=item B<--timeout>

HTTP request timeout in seconds (default: 30).

=item B<--unknown-http-status>

Threshold for unknown HTTP status (default: '%{http_code} < 200 or %{http_code} >= 300').

=item B<--warning-http-status>

Threshold for warning HTTP status.

=item B<--critical-http-status>

Threshold for critical HTTP status.

=back

=head1 DESCRIPTION

B<custom>.

=cut
