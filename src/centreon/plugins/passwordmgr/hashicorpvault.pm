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

package centreon::plugins::passwordmgr::hashicorpvault;

use strict;
use warnings;
use Data::Dumper;
use centreon::plugins::http;
use Digest::MD5 qw(md5_hex);
use JSON::XS;

use vars qw($vault_connections);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class PasswordMgr: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class PasswordMgr: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    $options{options}->add_options(arguments => {
        'auth-method:s'    => { name => 'auth_method', default => 'token' },
        'auth-path:s'      => { name => 'auth_path' },
        'auth-settings:s%' => { name => 'auth_settings' },
        'map-option:s@'    => { name => 'map_option' },
        'secret-path:s@'   => { name => 'secret_path' },
        'vault-address:s'  => { name => 'vault_address'},
        'vault-port:s'     => { name => 'vault_port', default => '8200' },
        'vault-protocol:s' => { name => 'vault_protocol', default => 'http'},
        'vault-token:s'    => { name => 'vault_token'}
    });
    $options{options}->add_help(package => __PACKAGE__, sections => 'VAULT OPTIONS');

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, noptions => 1, default_backend => 'curl');
    return $self;
}

sub get_access_token {
    my ($self, %options) = @_;

    my $decoded;
    my $login = $self->parse_auth_method(method => $self->{auth_method}, settings => $self->{auth_settings});
    my $post_json = JSON::XS->new->utf8->encode($login);
    if (!defined($self->{auth_path}) || $self->{auth_path} eq '') {
        $self->{auth_path} = $self->{auth_method};
    }
    my $url_path = '/v1/auth/'. $self->{auth_path} . '/login/';
    $url_path .= $self->{auth_settings}->{username} if (defined($self->{auth_settings}->{username}) && $self->{auth_method} =~ 'userpass|login') ;

    my $content = $self->{http}->request(
        hostname => $self->{vault_address},
        port => $self->{vault_port},
        proto => $self->{vault_protocol},
        method => 'POST',
        header => ['Content-type: application/json'],
        query_form_post => $post_json,
        url_path => $url_path
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }
    if (defined($decoded->{errors}[0])) {
        $self->{output}->output_add(long_msg => "Error message : " . $decoded->{errors}[0], debug => 1);
        $self->{output}->add_option_msg(short_msg => "Authentication endpoint returns error code '" . $decoded->{errors}[0] . "' (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    my $access_token = $decoded->{auth}->{client_token};
    return $access_token;
}

sub parse_auth_method {
    my ($self, %options) = @_;

    my $login_settings;
    my $settings_mapping = {
        azure    => [ 'role', 'jwt' ],
        cert     => [ 'name' ],
        github   => [ 'token' ],
        ldap     => [ 'username', 'password' ],
        okta     => [ 'username', 'password', 'totp' ],
        radius   => [ 'username', 'password' ],
        userpass => [ 'username', 'password' ]
    };

    foreach (@{$settings_mapping->{$options{method}}}) {
        if (!defined($options{settings}->{$_})) {
            $self->{output}->add_option_msg(short_msg => 'Missing authentication setting: ' . $_);
            $self->{output}->option_exit();
        }
        $login_settings->{$_} = $options{settings}->{$_};
    };

    return $login_settings;
}

sub settings {
    my ($self, %options) = @_;

    if (!defined($options{option_results}->{vault_address}) || $options{option_results}->{vault_address} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set the --vault-address option");
        $self->{output}->option_exit();
    }

    if ($options{option_results}->{auth_method} eq 'token' && (!defined($options{option_results}->{vault_token}) || $options{option_results}->{vault_token} eq '')) {
        $self->{output}->add_option_msg(short_msg => "Please set the --vault-token option");
        $self->{output}->option_exit();
    }

    if (!defined($options{option_results}->{secret_path}) || $options{option_results}->{secret_path} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set the --secret-path option");
        $self->{output}->option_exit();
    }

    if (defined($options{option_results}->{auth_path})) {		
        $self->{auth_path} = lc($options{option_results}->{auth_path});
    }

    $self->{auth_method} = lc($options{option_results}->{auth_method});
    $self->{auth_settings} = defined($options{option_results}->{auth_settings}) && $options{option_results}->{auth_settings} ne '' ? $options{option_results}->{auth_settings} : {};
    $self->{vault_address} = $options{option_results}->{vault_address};
    $self->{vault_port} = $options{option_results}->{vault_port};
    $self->{vault_protocol} = $options{option_results}->{vault_protocol};
    $self->{vault_token} = $options{option_results}->{vault_token};

    if (lc($self->{auth_method}) !~ m/azure|cert|github|ldap|okta|radius|userpass|token/ ) {
        $self->{output}->add_option_msg(short_msg => "Incorrect or unsupported authentication method set in --auth-method");
        $self->{output}->option_exit();
    }
    foreach (@{$options{option_results}->{secret_path}}) {
        $self->{request_endpoint}->{$_} = '/v1/' . $_;
    }

    if (defined($options{option_results}->{auth_method}) && $options{option_results}->{auth_method} ne 'token') {
        $self->{vault_token} = $self->get_access_token(%options);
    };

    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    if (defined($self->{vault_token})) {
        $self->{http}->add_header(key => 'X-Vault-Token', value => $self->{vault_token});
    }
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings(%options);
    my ($raw_data, $raw_response);
    foreach my $endpoint (keys %{$self->{request_endpoint}}) {
        my $json;
        my $response = $self->{http}->request(
            hostname => $self->{vault_address},
            port => $self->{vault_port},
            proto => $self->{vault_protocol},
            method => 'GET',
            url_path => $self->{request_endpoint}->{$endpoint}
        );
        $self->{output}->output_add(long_msg => $response, debug => 1);

        eval {
            $json = JSON::XS->new->utf8->decode($response);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode Vault JSON response: $@");
            $self->{output}->option_exit();
        }

        if ((defined($json->{data}->{metadata}->{deletion_time}) && $json->{data}->{metadata}->{deletion_time} ne '') || $json->{data}->{metadata}->{destroyed} eq 'true') {
            $self->{output}->add_option_msg(short_msg => "This secret is not valid anymore");
            $self->{output}->option_exit();
        }

        foreach (keys %{$json->{data}->{data}}) {
            $self->{lookup_values}->{'key_' . $endpoint} = $_;
            $self->{lookup_values}->{'value_' . $endpoint} = $json->{data}->{data}->{$_};
        }
        push(@{$raw_data}, $json);
        push(@{$raw_response}, $response);
    }

    return ($raw_data, $raw_response);
}

sub do_map {
    my ($self, %options) = @_;

    return if (!defined($options{option_results}->{map_option}));
    foreach (@{$options{option_results}->{map_option}}) {
        next if (! /^(.+?)=(.+)$/);

        my ($option, $map) = ($1, $2);

        # Change %{xxx} options usage
        while ($map =~ /\%\{(.*?)\}/g) {
            my $sub = '';
            $sub = $self->{lookup_values}->{$1} if (defined($self->{lookup_values}->{$1}));
            $map =~ s/\%\{$1\}/$sub/g;
        }
        $option =~ s/-/_/g;
        $options{option_results}->{$option} = $map;
    }
}

sub manage_options {
    my ($self, %options) = @_;

    my ($content, $debug) = $self->request_api(%options);
    if (!defined($content)) {
        $self->{output}->add_option_msg(short_msg => "Cannot read Vault information");
        $self->{output}->option_exit();
    }
    $self->do_map(%options);
    $self->{output}->output_add(long_msg => Data::Dumper::Dumper($debug), debug => 1) if ($self->{output}->is_debug());
}

1;

__END__

=head1 NAME

HashiCorp Vault global

=head1 SYNOPSIS

HashiCorp Vault class
To be used with K/V engines

=head1 VAULT OPTIONS

=over 8

=item B<--vault-address>

IP address of the HashiCorp Vault server (mandatory).

=item B<--vault-port>

Port of the HashiCorp Vault server (default: '8200').

=item B<--vault-protocol>

HTTP of the HashiCorp Vault server.
Can be: 'http', 'https' (default: http).

=item B<--auth-method>

Authentication method to log in against the Vault server.
Can be: 'azure', 'cert', 'github', 'ldap', 'okta', 'radius', 'userpass' (default: 'token');

=item B<--auth-path>

Authentication path for 'userpass'. Is an optional setting.

More information here: https://developer.hashicorp.com/vault/docs/auth/userpass#configuration

=item B<--vault-token>

Directly specify a valid token to log in (only for --auth-method='token').

=item B<--auth-settings>

Required information to log in according to the selected method.
Examples:
for 'userpass': --auth-settings='username=user1' --auth-settings='password=my_password'
for 'azure': --auth-settings='role=my_azure_role' --auth-settings='jwt=my_azure_token'

More information here: https://www.vaultproject.io/api-docs/auth

=item B<--secret-path>

Location of the secret in the Vault K/V engine (mandatory - Can be multiple).
Examples:
for v1 engine: --secret-path='mysecrets/servicecredentials'
for v2 engine: --secret-path='mysecrets/data/servicecredentials?version=12'

More information here: https://www.vaultproject.io/api-docs/secret/kv

=item B<--map-option>

Overload Plugin option with K/V values.
Use the following syntax:
the_option_to_overload='%{key_$secret_path$}' or
the_option_to_overload='%{value_$secret_path$}'
Example:
--map-option='username=%{key_mysecrets/servicecredentials}'
--map-option='password=%{value_mysecrets/servicecredentials}'

=back

=head1 DESCRIPTION

B<hashicorpvault>.

=cut
