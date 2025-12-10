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

package centreon::plugins::passwordmgr::centreonvault;

use strict;
use warnings;
use Data::Dumper;
use centreon::plugins::http;
use JSON::XS;
use MIME::Base64;
use Crypt::OpenSSL::AES;
use centreon::plugins::statefile;

my $VAULT_PATH_REGEX = qr/^secret::hashicorp_vault::([^:]+)::(.+)$/;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class PasswordMgr needs an 'output' argument that must be of type centreon::plugins::output.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        print "Class PasswordMgr needs an 'options' argument that must be of type centreon::plugins::options.\n";
        $options{output}->option_exit();
    }

    $options{options}->add_options(arguments => {
        'vault-config:s'    => { name => 'vault_config',    default => '/etc/centreon-engine/centreonvault.json'},
        'vault-cache:s'     => { name => 'vault_cache',     default => '/var/lib/centreon/centplugins/centreonvault_session'},
        'vault-env-file:s'  => { name => 'vault_env_file',  default => '/usr/share/centreon/.env'},
    });

    $options{options}->add_help(package => __PACKAGE__, sections => 'VAULT OPTIONS');

    $self->{output} = $options{output};

    # to access the vault, http protocol management is needed
    $self->{http} = centreon::plugins::http->new(%options, noptions => 1, default_backend => 'curl', insecure => 1);

    # to store the token and its expiration date, a statefile is needed
    $self->{cache} = centreon::plugins::statefile->new();

    return $self;
}

sub extract_map_options {
    my ($self, %options) = @_;

    $self->{map_option} = [];

    # Parse all options to find '/# .*\:\:secret\:\:(.*)/' pattern in the options values and add entries in map_option
    foreach my $option (keys %{$options{option_results}}) {
        if (defined($options{option_results}{$option})) {
            next if ($option eq 'map_option');
            if (ref($options{option_results}{$option}) eq 'ARRAY') {
                foreach (@{$options{option_results}{$option}}) {
                    if ($_ =~ $VAULT_PATH_REGEX) {
                        push (@{$self->{request_endpoint}}, "/v1/$1::$2");
                        push (@{$self->{map_option}}, $option."=%".$_);
                    }
                }
            } else {

                if (my ($path, $secret) = $options{option_results}{$option} =~ $VAULT_PATH_REGEX) {
                    push (@{$self->{request_endpoint}}, "/v1/" . $path . "::" . $secret);
                    push (@{$self->{map_option}}, $option."=%".$options{option_results}{$option});
                }
            }
        }
    }
}

sub vault_settings {
    my ($self, %options) = @_;

    if (centreon::plugins::misc::is_empty($options{option_results}->{vault_config})) {
        $self->{output}->add_option_msg(short_msg => "Please provide a Centreon Vault configuration file path with --vault-config option");
        $self->{output}->option_exit();
    }
    if (! -f $options{option_results}->{vault_config}) {
        $self->{output}->add_option_msg(short_msg => "File '$options{option_results}->{vault_config}' could not be found.");
        $self->{output}->option_exit();
    }
    $self->{vault_cache}    = $options{option_results}->{vault_cache};
    $self->{vault_env_file} = $options{option_results}->{vault_env_file};
    $self->{vault_config}   = $options{option_results}->{vault_config};


    my $file_content = do {
        local $/ = undef;
        if (!open my $fh, "<", $options{option_results}->{vault_config}) {
            $self->{output}->add_option_msg(short_msg => "Could not read file $options{option_results}->{vault_config}: $!");
            $self->{output}->option_exit();
        }
        <$fh>;
    };

    # decode the JSON content of the file
    my $json = centreon::plugins::misc::json_decode($file_content);
    if (!defined($json)) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode JSON : $file_content\n");
        $self->{output}->option_exit();
    }

    # set the default values
    $self->{vault}->{protocol} = 'https';
    $self->{vault}->{url} = '127.0.0.1';
    $self->{vault}->{port} = '8100';

    # define the list of expected attributes in the JSON file
    my @valid_json_options = (
        'protocol',
        'url',
        'port',
        'root_path',
        'token',
        'secret_id',
        'role_id'
    );

    # set the object fields when the json fields are not empty
    foreach my $valid_option (@valid_json_options) {
        $self->{vault}->{$valid_option} = $json->{$valid_option}
            if ( !centreon::plugins::misc::is_empty( $json->{ $valid_option } ) );
    }

    return 1;
}

sub get_decryption_key {
    my ($self, %options) = @_;

    # try getting APP_SECRET from the environment variables
    if ( !centreon::plugins::misc::is_empty($ENV{'APP_SECRET'}) ) {
        return $ENV{'APP_SECRET'};
    }

    # try getting APP_SECRET defined in the env file (default: /usr/share/centreon/.env) file
    my $fh;
    return undef if (!open $fh, "<", $self->{vault_env_file});
    for my $line (<$fh>) {
        if ($line =~ /^APP_SECRET=(.*)$/) {
            return $1;
        }
    }

    return undef;
}

sub extract_and_decrypt {
    my ($self, %options) = @_;

    my $input = decode_base64($options{data});
    my $key   = $options{key};

    # with AES-256, the IV length must 16 bytes
    my $iv_length = 16;
    # extract the IV, the hashed data, the encrypted data
    my $iv             = substr($input, 0, $iv_length);     # initialization vector
    my $hashed_data    = substr($input, $iv_length, 64);    # hmac of the original data, for integrity control
    my $encrypted_data = substr($input, $iv_length + 64);   # data to decrypt

    # Creating the AES decryption object
    my $cipher;
    eval {
        $cipher = Crypt::OpenSSL::AES->new(
            $key,
            {
                'cipher'  => 'AES-256-CBC',
                'iv'      => $iv
            }
        );
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "There was an error while creating the AES object: " . $@);
        $self->{output}->option_exit();
    }

    # Decrypting the data
    my $decrypted_data;
    eval {$decrypted_data = $cipher->decrypt($encrypted_data);};
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "There was an error while decrypting an AES-encrypted data: " . $@);
        $self->{output}->option_exit();
    }

    return $decrypted_data;
}

sub is_token_still_valid {
    my ($self) = @_;
    if (
            !defined($self->{auth})
            || centreon::plugins::misc::is_empty($self->{auth}->{token})
            || centreon::plugins::misc::is_empty($self->{auth}->{expiration_epoch})
            || $self->{auth}->{expiration_epoch} !~ /\d+/
            || $self->{auth}->{expiration_epoch} <= time()
    ) {
        $self->{output}->output_add(long_msg => "The token is missing or has expired or is invalid.", debug => 1);
        return undef;
    }
    $self->{output}->output_add(long_msg => "The cached token is still valid.", debug => 1);
    # Possible enhancement: check the token validity by calling this endpoint: /v1/auth/token/lookup-self
    # {"request_id":"XXXXX","lease_id":"","renewable":false,"lease_duration":0,"data":{"accessor":"XXXXXXX","creation_time":1732294406,"creation_ttl":2764800,"display_name":"approle","entity_id":"XXX","expire_time":"2024-12-24T16:53:26.932122122Z","explicit_max_ttl":0,"id":"hvs.secretToken","issue_time":"2024-11-22T16:53:26.932129132Z","meta":{"role_name":"myvault"},"num_uses":0,"orphan":true,"path":"auth/approle/login","policies":["default","myvault"],"renewable":true,"ttl":2764724,"type":"service"},"wrap_info":null,"warnings":null,"auth":null,"mount_type":"token"}

    return 1;
}

sub check_authentication {
    my ($self, %options) = @_;

    # prepare the cache (aka statefile)
    $self->{cache}->check_options(option_results => $options{option_results});
    my ($dir, $file, $suffix) = $options{option_results}->{vault_cache} =~ /^(.*\/)([^\/]+)(_.*)?$/;

    # Try reading the cache file
    if ($self->{cache}->read(
        statefile        => $file,
        statefile_suffix => defined($suffix) ? $suffix : '',
        statefile_dir    => $dir,
        statefile_format => 'json'
    )) {
        # if the cache file could be read, get the token and its expiration date
        $self->{auth} = {
            token            => $self->{cache}->get(name => 'token'),
            expiration_epoch => $self->{cache}->get(name => 'expiration_epoch')
        };
    }

    # if it is not valid, authenticate to get a new token
    if ( !$self->is_token_still_valid() ) {
        return $self->authenticate();
    }

    return 1;
}

sub authenticate {
    my ($self) = @_;

    # initial value: assuming the role and secret id might not be encrypted
    my $role_id   = $self->{vault}->{role_id};
    my $secret_id = $self->{vault}->{secret_id};
    if (centreon::plugins::misc::is_empty($role_id) || centreon::plugins::misc::is_empty($secret_id)) {
        $self->{output}->add_option_msg(short_msg => "Unable to authenticate to the vault: role_id or secret_id is empty.");
        $self->{output}->option_exit();
    }
    my $decryption_key = $self->get_decryption_key();

    # Decrypt the role_id and the secret_id if we have a decryption key
    if ( !centreon::plugins::misc::is_empty($decryption_key) ) {
        $role_id = $self->extract_and_decrypt(
            data => $role_id,
            key  => $decryption_key
        );
        $secret_id = $self->extract_and_decrypt(
            data => $secret_id,
            key  => $decryption_key
        );
    }

    # Authenticate to get the token
    my ($auth_result_json) = $self->{http}->request(
        hostname        => $self->{vault}->{url},
        port            => $self->{vault}->{port},
        proto           => $self->{vault}->{protocol},
        method          => 'POST',
        url_path        => "/v1/auth/approle/login",
        query_form_post => "role_id=$role_id&secret_id=$secret_id",
        header          => [
            'Content-Type: application/x-www-form-urlencoded',
            'Accept: */*',
            'X-Vault-Request: true',
            'User-Agent: Centreon-Plugins'
        ]
    );

    # Convert the response into a JSON object
    my $auth_result_obj = centreon::plugins::misc::json_decode($auth_result_json);
    if (!defined($auth_result_obj)) {
        # exit with UNKNOWN status
        $self->{output}->add_option_msg(short_msg => "Cannot decode JSON response from the vault server: $auth_result_json.");
        $self->{output}->option_exit();
    }
    # Authentication to the vault has passed
    # store the token (.auth.client_token) and its expiration date (current date + .lease_duration)
    my $expiration_epoch = -1;
    my $lease_duration = $auth_result_obj->{auth}->{lease_duration};
    if ( defined($lease_duration)
            && $lease_duration =~ /\d+/
            && $lease_duration > 0 ) {
        $expiration_epoch = time() + $lease_duration;
    }
    $self->{auth} = {
        'token'            => $auth_result_obj->{auth}->{client_token},
        'expiration_epoch' => $expiration_epoch
    };
    $self->{cache}->write(data => $self->{auth}, name => 'auth');

    $self->{output}->output_add(long_msg => "Authenticating worked. Token valid until "
            . localtime($self->{auth}->{expiration_epoch}), debug => 1);

    return 1;
}



sub request_api {
    my ($self, %options) = @_;

    $self->vault_settings(%options);

    # check the authentication
    if (!$self->check_authentication(%options)) {
        $self->{output}->add_option_msg(short_msg => "Unable to authenticate to the vault.");
        $self->{output}->option_exit();
    }

    $self->{lookup_values} = {};

    foreach my $item (@{$self->{request_endpoint}}) {
        # Extract vault name configuration from endpoint
        # 'vault::/v1/<root_path>/monitoring/hosts/7ad55afc-fa9e-4851-85b7-e26f47e421d7'
        my ($endpoint, $secret) = $item =~ /^(.*)\:\:(.*)$/;


        my ($response) = $self->{http}->request(
            hostname => $self->{vault}->{url},
            port => $self->{vault}->{port},
            proto => $self->{vault}->{protocol},
            method => 'GET',
            url_path => $endpoint,
            header => [
                'Accept: application/json',
                'User-Agent: Centreon-Plugins',
                'X-Vault-Request: true',
                'X-Vault-Token: ' . $self->{auth}->{token}
            ]
        );

        my $json = centreon::plugins::misc::json_decode($response);
        if (!defined($json->{data})) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode Vault JSON response: $response");
            $self->{output}->option_exit();
        };

        foreach my $secret_name (keys %{$json->{data}->{data}}) {
            # e.g. secret::hashicorp_vault::myspace/data/snmp::PubCommunity
            $self->{lookup_values}->{'secret::hashicorp_vault::' .  substr($endpoint, index($endpoint, '/', 1) + 1) . '::' . $secret_name} = $json->{data}->{data}->{$secret_name};
        }
    }
}

sub do_map {
    my ($self, %options) = @_;

    foreach my $mapping (@{$self->{map_option}}) {
        my ($opt_name, $opt_value) = $mapping =~ /^(.+?)=%(.+)$/ or next;
        $opt_name =~ s/-/_/g;
        $options{option_results}->{$opt_name} = defined($self->{lookup_values}->{$opt_value}) ? $self->{lookup_values}->{$opt_value} : $opt_value;
    }
}

sub manage_options {
    my ($self, %options) = @_;

    $self->extract_map_options(%options);

    return if (scalar(@{$self->{map_option}}) <= 0);

    $self->request_api(%options);
    $self->do_map(%options);
}

1;


=head1 NAME

Centreon Vault password manager

=head1 SYNOPSIS

Centreon Vault password manager

To be used with an array containing keys/values saved in a secret path by resource

=head1 VAULT OPTIONS

=over 8

=item B<--vault-config>

Path to the file defining access to the Centreon vault (default: C</etc/centreon-engine/centreonvault.json>).

=item B<--vault-cache>

Path to the file where the token to access the Centreon vault will be stored (default: C</var/lib/centreon/centplugins/centreonvault_session>).

=item B<--vault-env-file>

Path to the file containing the APP_SECRET variable (default: C</usr/share/centreon/.env>).

=back

=head1 DESCRIPTION

B<centreonvault>.

=cut

=head1 NAME

centreon::plugins::passwordmgr::centreonvault - Module for getting secrets from Centreon Vault.

=head1 SYNOPSIS

  use centreon::plugins::passwordmgr::centreonvault;

  my $vault = centreon::plugins::passwordmgr::centreonvault->new(output => $output, options => $options);
  $vault->manage_options(option_results => \%option_results);

=head1 DESCRIPTION

This module provides methods to retrieve secrets (passwords, SNMP communities, ...) from Centreon Vault (adequately
configured HashiCorp Vault).
It extracts and decrypt the information required to login to the vault from the vault configuration file, authenticates
to the vault, retrieves secrets, and maps them to the corresponding options for the centreon-plugins to work with.

=head1 METHODS

=head2 new

  my $vault = centreon::plugins::passwordmgr::centreonvault->new(%options);

Creates a new `centreon::plugins::passwordmgr::centreonvault` object. The `%options` hash can include:

=over 4

=item * output

The output object for displaying debug and error messages.

=item * options

The options object for handling command-line options.

=back

=head2 extract_map_options

  $vault->extract_map_options(option_results => \%option_results);

Extracts and maps options that match the Vault path regex pattern (C</^secret::hashicorp_vault::([^:]+)::(.+)$/>). The
`%option_results` hash should include the command-line options.

=head2 vault_settings

  $vault->vault_settings(option_results => \%option_results);

Loads and validates the Vault configuration from the specified file.
The `%option_results` hash should include the command-line options.

=head2 get_decryption_key

  my $key = $vault->get_decryption_key();

Retrieves the decryption key from C<APP_SECRET> environment variable. It will look for it in the the specified
environment file if it is not available in the environment variables.

=head2 extract_and_decrypt

  my $decrypted_data = $vault->extract_and_decrypt(data => $data, key => $key);

Decrypts the given data using the specified key. The options must include:

=over 4

=item * data

The base64-encoded data to decrypt.

=item * key

The base64-encoded decryption key.

=back

=head2 is_token_still_valid

  my $is_valid = $vault->is_token_still_valid();

Checks if there is a token in the cache and if it is still valid based on its expiration date. Returns 1 if valid, otherwise undef.

=head2 check_authentication

  $vault->check_authentication(option_results => \%option_results);

Checks the authentication status and retrieves a new token if necessary. The `%option_results` hash should include the command-line options.

=head2 authenticate

  $vault->authenticate();

Authenticates to the Vault, retrieves a new token and stores it in the dedicated cache file.

=head2 request_api

  $vault->request_api(option_results => \%option_results);

Sends requests to the Vault API to retrieve secrets. The `%option_results` hash should include the command-line options.

=head2 do_map

  $vault->do_map(option_results => \%option_results);

Maps the retrieved secrets to the corresponding options. The `%option_results` hash should include the command-line options.
Calling this method will update the `%option_results` hash replacing vault paths with the retrieved secrets.

=head2 manage_options

  $vault->manage_options(option_results => \%option_results);

Manages the options by extracting, requesting, and mapping secrets. The `%option_results` hash should include the command-line options.

NB: This is the main method to be called from outside the module. All other methods are intended to be used internally.

=head1 AUTHOR

Centreon

=head1 LICENSE

Licensed under the Apache License, Version 2.0.

=cut
