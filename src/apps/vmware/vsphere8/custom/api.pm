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

package apps::vmware::vsphere8::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use MIME::Base64;
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
        $options{options}->add_options(
            arguments => {
                'hostname:s' => { name => 'hostname' },
                'port:s'     => { name => 'port' },
                'proto:s'    => { name => 'proto' },
                'username:s' => { name => 'username' },
                'password:s' => { name => 'password' },
                'timeout:s'  => { name => 'timeout' }
            }
        );
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http}   = centreon::plugins::http->new(%options, 'default_backend' => 'curl');
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

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port}     = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto}    = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout}  = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : '';
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if ($self->{username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --username option.");
        $self->{output}->option_exit();
    }
    if ($self->{password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --password option.");
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    # add options of this api
    $self->{option_results}->{username} = $self->{username};
    $self->{option_results}->{password} = $self->{password};
    $self->{option_results}->{warning_status} = '';
    $self->{option_results}->{critical_status} = '';
    $self->{option_results}->{unknown_status} = $self->{http_unknown_status};
}

sub settings {
    my ($self, %options) = @_;

    return 1 if (defined($self->{settings_done}));
    $self->build_options_for_httplib();

    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;

    return 1;
}

sub get_token {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(
            statefile => 'vsphere8_api_' . md5_hex(
                    $self->{hostname}
                    . ':' . $self->{port}
                    . '_' . $self->{username})
    );
    my $token = $self->{cache}->get(name => 'token');

    if (
        $has_cache_file == 0
        || !defined($token)
        || $options{force_authentication}
    ) {
        my $auth_string = MIME::Base64::encode_base64($self->{username} . ':' . $self->{password});
        chomp $auth_string;

        $self->settings();
        my $content = $self->{http}->request(
            method => 'POST',
            url_path => '/api/session',
            query_form_post => '',
            unknown_status => $self->{unknown_http_status},
            warning_status => $self->{warning_http_status},
            critical_status => $self->{critical_http_status},
            header => [
                    'Authorization: Basic ' . $auth_string,
                    'Content-Type: application/x-www-form-urlencoded'
            ]
        );

        $content =~ s/^"(.*)"$/$1/;
        $token = $content;

        my $data = {
            updated => time(),
            token => $token
        };
        $self->{cache}->write(data => $data);
    }

    return $token;
}

sub try_request_api {
    my ($self, %options) = @_;

    my $token = $self->get_token(%options);
    my ($content) = $self->{http}->request(
            url_path       => '/api' . $options{endpoint},
            get_param      => $options{get_param},
            header         => [ 'vmware-api-session-id: ' . $token ],
            unknown_status => '',
            insecure       => (defined($self->{option_results}->{insecure}) ? 1 : 0)
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '"
                . $self->{http}->get_code() . "'] [message: '"
                . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded = centreon::plugins::misc::json_decode($content);

    return $decoded;
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();
    my $api_response = $self->try_request_api(%options);

    # if the token is invalid, we try to authenticate again
    if (ref($api_response) eq 'HASH'
            && defined($api_response->{error_type})
            && $api_response->{error_type} eq 'UNAUTHENTICATED') {
        $api_response = $self->try_request_api('force_authentication' => 1, %options);
    }
    # if we could not authenticate, we exit
    if (ref($api_response) eq 'HASH' && defined($api_response->{error_type})) {
        my $full_message = '';
        for my $error_item (@{$api_response->{messages}}) {
            $full_message .= '[Id: ' . $error_item->{id} . ' - Msg: ' . $error_item->{default_message} . ' (' . join(', ', @{$error_item->{args}}) . ')]';
        }
        $self->{output}->add_option_msg(short_msg => "API returns error of type " . $api_response->{error_type} . ": " . $full_message);
        $self->{output}->option_exit();
    }
    return $api_response;
}

1;
__END__

=head1 NAME

apps::vmware::vsphere8::custom::api - Custom module for VMware vSphere 8 API.

=head1 SYNOPSIS

    use apps::vmware::vsphere8::custom::api;

    my $api = apps::vmware::vsphere8::custom::api->new(
        output => $output,
        options => $options
    );

    $api->set_options(option_results => $option_results);
    $api->check_options();
    my $response = $api->request_api(endpoint => '/vcenter/host');

=head1 DESCRIPTION

This module provides methods to interact with the VMware vSphere 8 REST API. It handles authentication, caching, and API requests.

=head1 METHODS

=head2 new

    my $api = apps::vmware::vsphere8::custom::api->new(%options);

Creates a new `apps::vmware::vsphere8::custom::api` object.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<output> - An output object for messages.

=item * C<options> - An options object for adding command-line options.

=back

=back

=head2 set_options

    $api->set_options(option_results => $option_results);

Sets the options for the API module.

=over 4

=item * C<option_results> - A hash of option results.

=back

=head2 set_defaults

    $api->set_defaults();

Sets the default options for the API module.

=head2 check_options

    $api->check_options();

Checks and processes the provided options.

=head2 build_options_for_httplib

    $api->build_options_for_httplib();

Builds the options for the HTTP library.

=head2 settings

    $api->settings();

Configures the HTTP settings for the API requests.

=head2 get_token

    my $token = $api->get_token(%options);

Retrieves the authentication token from the cache or requests a new one if necessary.

=over 4

=item * C<%options> - A hash of options.

=back

=head2 try_request_api

    my $response = $api->try_request_api(%options);

Attempts to make an API request with the provided options.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<endpoint> - The API endpoint to request.

=item * C<get_param> - Additional GET parameters for the request.

=item * C<force_authentication> - Force re-authentication if set to true.

=back

=back

=head2 request_api

    my $response = $api->request_api(%options);

Calls try_request_api and recalls it forcing authentication if the first call fails.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<method> - The HTTP method to use (examples: GET, POST).

=item * C<endpoint> - The API endpoint to request.

=item * C<get_param> - Additional GET parameters for the request.

=back

=back

=head1 REST API OPTIONS

Command-line options for VMware vSphere 8 API:

=over 8

=item B<--hostname>

Define the hostname of the vSphere server.

=item B<--port>

Define the port of the vSphere server (default: 443).

=item B<--proto>

Define the protocol to use (default: https).

=item B<--username>

Define the username for authentication.

=item B<--password>

Define the password for authentication.

=item B<--timeout>

Define the timeout for API requests (default: 10 seconds).

=back

=head1 AUTHOR

Centreon

=head1 LICENSE

Licensed under the Apache License, Version 2.0.

=cut