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

package apps::voip::3cx::restapi::custom::api;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
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
        $options{options}->add_options(arguments =>  {
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port'},
            'proto:s'                => { name => 'proto' },
            'api-username:s'         => { name => 'api_username' },
            'api-password:s'         => { name => 'api_password' },
            'auth-mode:s'            => { name => 'auth_mode', default => 'oauth2' },
            'timeout:s'              => { name => 'timeout', default => 30 },
            'unknown-http-status:s'  => { name => 'unknown_http_status' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }

    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname}               = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : '';
    $self->{port}                   = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto}                  = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout}                = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{ssl_opt}                = (defined($self->{option_results}->{ssl_opt})) ? $self->{option_results}->{ssl_opt} : undef;
    $self->{api_username}           = (defined($self->{option_results}->{api_username})) ? $self->{option_results}->{api_username} : '';
    $self->{api_password}           = (defined($self->{option_results}->{api_password})) ? $self->{option_results}->{api_password} : '';
    $self->{auth_mode}              = (defined($self->{option_results}->{auth_mode})) ? $self->{option_results}->{auth_mode} : 'oauth2';
    $self->{unknown_http_status}    = (defined($self->{option_results}->{unknown_http_status})) ? $self->{option_results}->{unknown_http_status} : '%{http_code} < 200 or %{http_code} >= 300' ;
    $self->{warning_http_status}    = (defined($self->{option_results}->{warning_http_status})) ? $self->{option_results}->{warning_http_status} : '';
    $self->{critical_http_status}   = (defined($self->{option_results}->{critical_http_status})) ? $self->{option_results}->{critical_http_status} : '';

    if ($self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-username option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-password option.');
        $self->{output}->option_exit();
    }
    if ($self->{auth_mode} !~ /^(oauth2|login)$/) {
        $self->{output}->add_option_msg(short_msg => "Invalid --auth-mode value '$self->{auth_mode}'. Must be 'oauth2' or 'login'.");
        $self->{output}->option_exit();
    }
    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{ssl_opt} = $self->{ssl_opt};
    $self->{option_results}->{timeout} = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json;charset=UTF-8');
    if (defined($self->{auth_header})) {
        $self->{http}->add_header(key => 'Authorization', value => $self->{auth_header});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub authenticate {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile => '3cx_api_' . md5_hex($self->{option_results}->{hostname}) . '_' . md5_hex($self->{option_results}->{api_username}));
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
            $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');
            $self->{http}->set_options(%{$self->{option_results}});

            my $post_data = 'client_id=' . $self->{api_username} .
                            '&client_secret=' . $self->{api_password} .
                            '&grant_type=client_credentials';

            $content = $self->{http}->request(
                method          => 'POST',
                query_form_post => $post_data,
                url_path        => '/connect/token',
                unknown_status  => $self->{unknown_http_status},
                warning_status  => $self->{warning_http_status},
                critical_status => $self->{critical_http_status}
            );

            eval { $decoded = JSON::XS->new->decode($content); };
            if ($@ || !defined($decoded) || !defined($decoded->{access_token})) {
                $self->{output}->add_option_msg(short_msg => "OAuth2 authentication failed. Check client_id/client_secret and ensure the API client has Admin role (add --debug for details).");
                $self->{output}->option_exit();
            }

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

            my $post_data = '{"Username":"' . $self->{api_username} . '","Password":"' . $self->{api_password} . '"}';

            $content = $self->{http}->request(
                method          => 'POST',
                query_form_post => $post_data,
                url_path        => '/webclient/api/Login/GetAccessToken',
                unknown_status  => $self->{unknown_http_status},
                warning_status  => $self->{warning_http_status},
                critical_status => $self->{critical_http_status}
            );

            eval { $decoded = JSON::XS->new->decode($content); };
            if ($@) {
                $self->{output}->add_option_msg(short_msg => "Cannot decode login response: $@");
                $self->{output}->option_exit();
            }
            if (!defined($decoded) || !defined($decoded->{Status})) {
                $self->{output}->add_option_msg(short_msg => "Login failed: unexpected response (add --debug for details).");
                $self->{output}->option_exit();
            }
            if ($decoded->{Status} eq 'Required2FA') {
                $self->{output}->add_option_msg(short_msg => "Login failed: 2FA is enabled on this account. Please disable 2FA for the monitoring account.");
                $self->{output}->option_exit();
            }
            if ($decoded->{Status} ne 'AuthSuccess' || !defined($decoded->{Token}->{access_token})) {
                $self->{output}->add_option_msg(short_msg => "Login failed: status=" . $decoded->{Status} . " (add --debug for details).");
                $self->{output}->option_exit();
            }

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

    if (!defined($self->{auth_header})) {
        $self->authenticate(statefile => $self->{cache});
    }

    $self->settings();

    my $content = $self->{http}->request(
        %options,
        unknown_status => $self->{unknown_http_status},
        warning_status => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(short_msg => "Error while retrieving data (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

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
        if (ref($status) ne 'ARRAY') {
            $status = JSON::XS->new->decode($status);
        }
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
For 'oauth2' mode (Enterprise): the client_id of the API client created in 3CX admin console.
For 'login' mode (Pro): the email or extension number of a System Owner account (2FA must be disabled).

=item B<--api-password>

Define the password for authentication.
For 'oauth2' mode (Enterprise): the client_secret of the API client.
For 'login' mode (Pro): the password of the System Owner account.

=item B<--auth-mode>

Define the authentication mode (default: 'oauth2').

'oauth2': for 3CX Enterprise edition.
Uses OAuth2 client_credentials flow via POST /connect/token.
Requires an API client created in 3CX admin console (/#/office/integrations/api).
The API client must have at least the 'Admin' role.

'login': for 3CX Pro edition.
Uses username/password login via POST /webclient/api/Login/GetAccessToken.
Requires a System Owner account with 2FA disabled.
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
