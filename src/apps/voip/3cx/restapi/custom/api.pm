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

package apps::voip::3cx::restapi::custom::api;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use centreon::plugins::misc qw/json_decode json_encode/;
use Digest::SHA qw(sha256_hex);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    unless ($options{output}) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless $options{options};

    $options{options}->add_options(arguments =>  {
        'hostname:s'             => { name => 'hostname', not_empty => 1 },
        'port:s'                 => { name => 'port', default => 443, type => 'port', not_empty => 1 },
        'proto:s'                => { name => 'proto', default => 'https', type => 'protocol_http', not_empty => 1 },
        'api-username:s'         => { name => 'api_username', not_empty => 1 },
        'api-password:s'         => { name => 'api_password', not_empty => 1 },
        'auth-mode:s'            => { name => 'auth_mode', default => 'oauth2', is_in => [ 'oauth2', 'login' ], not_empty => 1 },
        'timeout:s'              => { name => 'timeout', default => 30, not_empty => 1 },
        'unknown-http-status:s'  => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
        'warning-http-status:s'  => { name => 'warning_http_status', default => '' },
        'critical-http-status:s' => { name => 'critical_http_status', default => '' }
    }) unless $options{noptions};

    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/hostname port proto timeout ssl_opt api_username api_password auth_mode unknown_http_status warning_http_status critical_http_status/;

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{$_} = $self->{$_}
        foreach qw/hostname port proto ssl_opt timeout/;
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json;charset=UTF-8');
    $self->{http}->add_header(key => 'Authorization', value => $self->{auth_header})
        if $self->{auth_header};

    $self->{http}->set_options(%{$self->{option_results}});
}

sub authenticate {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => '3cx_api_' . sha256_hex($self->{option_results}->{hostname} . '_' . $self->{option_results}->{api_username}));
    my $auth_header = $options{statefile}->get(name => 'auth_header');
    my $expires_on  = $options{statefile}->get(name => 'expires_on');

    if ($has_cache_file == 0 || !defined($auth_header) || !defined($expires_on) || (($expires_on - time()) < 10)) {
        $self->build_options_for_httplib();
        my ($content, $decoded);

        if ($self->{auth_mode} eq 'oauth2') {
            # 3CX Enterprise: OAuth2 client_credentials flow
            # POST /connect/token with client_id / client_secret
            # Requires an API client created in 3CX admin console (/#/office/integrations/api)
            # The API client must have at least the 'Admin' role
            $self->{http}->set_options(%{$self->{option_results}});

            my $post_params = { 'client_id' => $self->{api_username},
                            'client_secret' => $self->{api_password},
                            'grant_type' => 'client_credentials' };
            $content = $self->{http}->request(
                method          => 'POST',
                post_params     => $post_params,
                url_path        => '/connect/token',
                unknown_status  => $self->{unknown_http_status},
                warning_status  => $self->{warning_http_status},
                critical_status => $self->{critical_http_status}
            );


            $decoded = json_decode($content, silence => 1);
            $self->{output}->option_exit(short_msg => "OAuth2 authentication failed. Check client_id/client_secret and ensure the API client has Admin role (add --debug for details).")
                unless ref $decoded eq 'HASH' && $decoded->{access_token};

            $auth_header = $decoded->{token_type} . ' ' . $decoded->{access_token};
            # expires_in is in seconds for v20
            $expires_on  = time() + $decoded->{expires_in} - 5;

        } elsif ($self->{auth_mode} eq 'login') {
            # 3CX Pro: username/password login
            # POST /webclient/api/Login/GetAccessToken
            # Requirements:
            #   - Account must have 'System Owner' role
            #   - 2FA must be disabled on the account
            #   - The poller IP must be whitelisted in 3CX admin console:
            #     Security > Console Restrictions > Allow access from specific IP addresses
            #     Without this, 3CX returns a degraded token (MaxRole: users) causing 403 errors
            $self->{http}->add_header(key => 'Content-Type', value => 'application/json;charset=UTF-8');
            $self->{http}->set_options(%{$self->{option_results}});

            my $post_params = { "Username" => $self->{api_username},
                                "Password" => $self->{api_password}
                              };
            $content = $self->{http}->request(
                method          => 'POST',
                query_form_post => json_encode($post_params, silence => 1),
                url_path        => '/webclient/api/Login/GetAccessToken',
                unknown_status  => $self->{unknown_http_status},
                warning_status  => $self->{warning_http_status},
                critical_status => $self->{critical_http_status}
            );

            $decoded = json_decode($content, output => $self->{output});
            $self->{output}->option_exit(short_msg => "Login failed: unexpected response (add --debug for details).")
                unless ref $decoded eq 'HASH' && $decoded->{Status};
            $self->{output}->option_exit(short_msg => "Login failed: 2FA is enabled on this account. Please disable 2FA for the monitoring account.")
                if $decoded->{Status} eq 'Required2FA';
            $self->{output}->option_exit(short_msg => "Login failed: status=" . $decoded->{Status} . " (add --debug for details).")
                if $decoded->{Status} ne 'AuthSuccess' || !defined($decoded->{Token}->{access_token});

            $auth_header = $decoded->{Token}->{token_type} . ' ' . $decoded->{Token}->{access_token};
            # expires_in is in seconds for v20
            $expires_on  = time() + $decoded->{Token}->{expires_in} - 5;
        }

        $options{statefile}->write(data => {
            last_timestamp => time(),
            auth_header    => $auth_header,
            expires_on     => $expires_on
        });
    }

    $self->{auth_header} = $auth_header;
}

sub request_api {
    my ($self, %options) = @_;

    $self->authenticate(statefile => $self->{cache})
        unless $self->{auth_header};

    $self->settings();

    my $content = $self->{http}->request(
        %options,
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );

    my $decoded = json_decode($content, silence => 1);
    $self->{output}->option_exit(short_msg => "Error while retrieving data (add --debug option for detailed message)")
        unless ref $decoded eq 'HASH';

    return $decoded;
}

sub internal_activecalls {
    my ($self, %options) = @_;

    # v20: endpoint moved to /xapi/v1/ActiveCalls, list is under 'value' key (OData)
    my $status = $self->request_api(method => 'GET', url_path => '/xapi/v1/ActiveCalls');
    return $status;
}

sub api_activecalls {
    my ($self, %options) = @_;

    my $status = $self->internal_activecalls();
    return $status->{value};
}

sub internal_extension_list {
    my ($self, %options) = @_;

    # v20: extensions are under /xapi/v1/Users endpoint (OData), list is under 'value' key
    # CurrentProfile renamed to CurrentProfileName, DND boolean replaced by CurrentProfileName
    my $status = $self->request_api(
        method   => 'GET',
        url_path => '/xapi/v1/Users?$select=Number,FirstName,LastName,IsRegistered,CurrentProfileName'
    );
    return $status;
}

sub api_extension_list {
    my ($self, %options) = @_;

    my $status = $self->internal_extension_list();
    return $status->{value};
}

sub internal_system_status {
    my ($self, %options) = @_;

    # v20: endpoint moved to /xapi/v1/SystemStatus
    # GetSingleStatus (Firewall/Phones) no longer exists, all health info is in SystemStatus
    my $status = $self->request_api(method => 'GET', url_path => '/xapi/v1/SystemStatus');
    return $status;
}

sub api_system_status {
    my ($self, %options) = @_;

    my $status = $self->internal_system_status();
    return $status;
}

sub internal_update_checker {
    my ($self, %options) = @_;

    my $status = $self->request_api(method => 'GET', url_path => '/xapi/v1/GetUpdatesStats()');
    if (ref($status) eq 'HASH') {
        $status = $status->{TcxUpdate};
        $status = json_decode($status, silence => 1)
            if ref($status) ne 'ARRAY';
    }
    return $status;
}

sub api_update_checker {
    my ($self, %options) = @_;

    return $self->internal_update_checker();
}

1;

__END__

=head1 NAME

3CX Rest API module (v20+)

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Define the name or the address of the 3CX server.

=item B<--port>

Define the port to connect to (default: '443').

=item B<--proto>

Define the protocol to reach the API (default: 'https').

=item B<--api-username>

Define the username for authentication.
For C<oauth2> mode (Enterprise): the client_id of the API client created in 3CX admin console.
For C<login> mode (Pro): the email or extension number of a System Owner account (C<2FA> must be disabled).

=item B<--api-password>

Define the password for authentication.
For C<oauth2> mode (Enterprise): the client_secret of the API client.
For C<login> mode (Pro): the password of the System Owner account.

=item B<--auth-mode>

Define the authentication mode (default: C<oauth2>).

C<oauth2>: for 3CX Enterprise edition.
Uses OAuth2 client_credentials flow via POST /connect/token.
Requires an API client created in 3CX admin console (/#/office/integrations/api).
The API client must have at least the 'Admin' role.

C<login>: for 3CX Pro edition.
Uses username/password login via POST /webclient/api/Login/GetAccessToken.
Requires a System Owner account with C<2FA> disabled.
IMPORTANT: The poller IP must be whitelisted in 3CX admin console under
Security > Console Restrictions > Allow access from specific IP addresses.
Without this, 3CX returns a degraded token causing 403 errors on all API endpoints.

=item B<--timeout>

Define the timeout in seconds (default: 30).

=item B<--unknown-http-status>

Define the conditions to match on the HTTP Status for the returned status to be UNKNOWN.
Default: '%{http_code} < 200 or %{http_code} >= 300'

=item B<--warning-http-status>

Define the conditions to match on the HTTP Status for the returned status to be WARNING.
Example: '%{http_code} == 500'

=item B<--critical-http-status>

Define the conditions to match on the HTTP Status for the returned status to be CRITICAL.
Example: '%{http_code} == 500'

=back

=cut
