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

package network::fortinet::fortiauthenticator::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::misc qw/format_opt json_decode/;
use MIME::Base64 qw/encode_base64/;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless $options{options};

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'api-token:s'            => { name => 'api_token',            default => '' },
            'api-username:s'         => { name => 'api_username',         default => '' },
            'hostname:s'             => { name => 'hostname',             default => '' },
            'port:s'                 => { name => 'port',                 default => 443 },
            'proto:s'                => { name => 'proto',                default => 'https' },
            'limit:s'                => { name => 'limit',                default => 20 },
            'timeout:s'              => { name => 'timeout',              default => 50 },
            'unknown-http-status:s'  => { name => 'unknown_http_status',  default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  => { name => 'warning_http_status',  default => '' },
            'critical-http-status:s' => { name => 'critical_http_status', default => '' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

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

    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/api_token api_username hostname port proto limit timeout unknown_http_status warning_http_status critical_http_status/;

    foreach (qw/hostname api_token api_username/) {
        $self->{output}->option_exit(short_msg => "Need to specify --".format_opt($_)." option.")
            if $self->{$_} eq '';
    }

    foreach (qw/limit port timeout/) {
        $self->{output}->option_exit(short_msg => "Invalid --".format_opt($_)." option.")
            unless $self->{$_} =~ /^\d+$/;
    }

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{$_} = $self->{$_}
        foreach (qw/hostname timeout port proto/);
}

sub settings {
    my ($self, %options) = @_;
    my $credentials = $self->{api_username}.':'.$self->{api_token};
    $self->{token} = encode_base64($credentials, '');

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Authorization', value => 'Basic ' . $self->{token})
        if $self->{token};
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub get_port {
    my ($self, %options) = @_;

    return $self->{port};
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    $self->{output}->output_add(
        long_msg => "URL: '" . $self->{proto} . '://' . $self->{hostname} . ':' . $self->{port} . $options{url_path} . "'",
        debug => 1
    );
    my $response = $self->{http}->request(%options);

    my $decoded = json_decode($response, output => $self->{output});
    if ($self->{http}->get_code() != 200) {
        $self->{output}->output_add(long_msg => "Error message: " . $decoded->{message}, debug => 1)
            if $decoded->{message};
        $self->{output}->option_exit(short_msg => "API return error code '" . ($decoded->{code} // $self->{http}->get_code()) . "' (add --debug option for detailed message)");
    }

    return $decoded;
}


sub request_api_paginate {
    my ($self, %options) = @_;
    my @objects;

    # Use custom limit on the first request only, afterward use the limit returned by the API
    my $opt = { 'limit' => $self->{limit} };
    while (1) {
        my $response = $self->request_api(
            method => $options{method},
            url_path => $options{url_path},
            get_params => $opt
        );
        undef $opt;

        last unless ref $response->{objects} eq 'ARRAY';
        push @objects, @{$response->{objects}};

        last unless $response->{meta} && $response->{meta}->{next};
        $options{url_path} = $response->{meta}->{next};
    }

    return \@objects;
}

sub fortiauthentificator_list_tokens {
    my ($self, %options) = @_;
    my $response = $self->request_api_paginate(
        method => 'GET',
        url_path => '/api/v1/fortitokens/'
    );
    return $response;
}

1;

__END__

=head1 NAME

FortiAuthenticator Rest API

=head1 REST API OPTIONS

FortiAuthenticator Rest API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (default: 443)

=item B<--proto>

Specify https if needed (default: 'https')

=item b<--api-username>

API username.

=item b<--api-token>

API token.

=item B<--limit>

Define the number of entries to retrieve for the pagination (default: 20). 

=item B<--timeout>

Set timeout in seconds (default: 50).

=back

=head1 DESCRIPTION

B<custom>.

=cut
