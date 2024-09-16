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

package storage::hp::primera::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
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
            'api-username:s'         => { name => 'api_username' },
            'api-password:s'         => { name => 'api_password' },
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port', default => 443 },
            'proto:s'                => { name => 'proto', default => 'https' },
            'timeout:s'              => { name => 'timeout', default => 30 },
            'unknown-http-status:s'  => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'HPE Primera API OPTIONS', once => 1);

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

    if (centreon::plugins::misc::is_empty($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if (centreon::plugins::misc::is_empty($self->{option_results}->{api_username})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-username option.');
        $self->{output}->option_exit();
    }
    if (centreon::plugins::misc::is_empty($self->{option_results}->{api_password})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-password option.');
        $self->{output}->option_exit();
    }
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{http}->add_header(key => 'Accept', value => 'application/json');

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port};
}

sub get_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile => 'hpe_primera_' . md5_hex($self->get_connection_info() . '_' . $self->{option_results}->{api_username}));
    my $auth_key = $self->{cache}->get(name => 'auth_key');

    if ($has_cache_file == 0 || !defined($auth_key) || $auth_key eq '' ) {
        my $json_request = {
            user     => $self->{option_results}->{api_username},
            password => $self->{option_results}->{api_password}
        };
        my $encoded;
        eval {
            $encoded = encode_json($json_request);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => 'An error occurred while encoding the credentials to a JSON string.');
            $self->{output}->option_exit();
        }

        my $content = $self->{http}->request(
            method => 'POST',
            url_path => '/api/v1/credentials',
            query_form_post => $encoded,
            unknown_status => $self->{option_results}->{unknown_http_status},
            warning_status => $self->{option_results}->{warning_http_status},
            critical_status => $self->{option_results}->{critical_http_status},
            header => ['Content-Type: application/json']
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "An error occurred while decoding the response ('$content').");
            $self->{output}->option_exit();
        }

        $auth_key = $decoded->{key};
        my $data = {
            updated  => time(),
            auth_key => $auth_key
        };
        $self->{cache}->write(data => $data);
    }

    return $auth_key;
}

sub clean_token {
    my ($self, %options) = @_;

    my $data = { updated => time() };
    $self->{cache}->write(data => $data);
}

sub request_api {
    my ($self, %options) = @_;

    my $get_param = [];
    if (defined($options{get_param})) {
        $get_param = $options{get_param};
    }

    my $token = $self->get_token();
    my ($content) = $self->{http}->request(
        url_path        => $options{endpoint},
        get_param       => $get_param,
        header          => [ 'Authorization: Bearer ' . $token ],
        unknown_status  => '',
        warning_status  => '',
        critical_status => ''
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->allow_nonref(1)->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

HPE Primera REST API

=head1 HPE Primera API OPTIONS

HPE Primera REST API

=over 8

=item B<--hostname>

Address of the server that hosts the API.

=item B<--port>

Define the TCP port to use to reach the API (default: 443).

=item B<--proto>

Define the protocol to reach the API (default: 'https').

=item B<--api-username>

Define the username for authentication.

=item B<--api-password>

Define the password associated with the username.

=item B<--timeout>

Define the timeout in seconds for HTTP requests (default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
