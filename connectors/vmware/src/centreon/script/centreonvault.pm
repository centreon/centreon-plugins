#
# Copyright 2025-Present Centreon (http://www.centreon.com/)
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

package centreon::script::centreonvault;

use strict;
use warnings;
use JSON::XS;
use MIME::Base64;
use Crypt::OpenSSL::AES;
use Net::Curl::Easy qw(:constants);
use centreon::vmware::common;

my $VAULT_PATH_REGEX = qr/^secret::hashicorp_vault::([^:]+)::(.+)$/;

sub new {
    my ($class, %options) = @_;
    my $self  = bless \%options, $class;
    # mandatory options:
    # - logger: logger object
    # - config_file: path of a JSON vault config file

    $self->{enabled} = 1;
    $self->{crypted_credentials} = 1;

    if ( !$self->init() ) {
        $self->{enabled} = 0;
        $self->{logger}->writeLogInfo("Something happened during init() method that makes Centreonvault not usable. Ignore this if you don't use Centreonvault.");
    }
    return $self;
}


sub init {
    my ($self, %options) = @_;

    $self->check_options() or return undef;

    # check if the following information is available
    $self->{logger}->writeLogDebug("Reading Vault configuration from file " . $self->{config_file} . ".");
    $self->{vault_config} = centreon::vmware::common::parse_json_file( 'json_file' => $self->{config_file} );
    if (defined($self->{vault_config}->{error_message})) {
        $self->{logger}->writeLogError("Error while parsing " . $self->{config_file} . ": "
            . $self->{vault_config}->{error_message});
        return undef;
    }

    $self->check_configuration() or return undef;

    $self->{logger}->writeLogDebug("Vault configuration read. Name: " . $self->{vault_config}->{name}
        . ". Url: " . $self->{vault_config}->{url} . ".");

    # Create the Curl object, it will be used several times
    $self->{curl_easy} = Net::Curl::Easy->new();
    $self->{curl_easy}->setopt( CURLOPT_USERAGENT, "Centreon VMware daemon's centreonvault.pm");

    return 1;
}

sub check_options {
    my ($self, %options) = @_;

    if ( !defined($self->{logger}) ) {
        die "FATAL: No logger given to the constructor. Centreonvault cannot be used.";
    }
    if ( !defined($self->{config_file})) {
        $self->{logger}->writeLogError("No config file given to the constructor. Centreonvault cannot be used.");
        return undef;
    }
    if ( ! -f $self->{config_file} ) {
        $self->{logger}->writeLogError("The given configuration file " . $self->{config_file}
            . " does not exist. Passwords won't be retrieved from Centreonvault. Ignore this error if you don't use Centreonvault.");
        return undef;
    }

    return 1;
}

sub check_configuration {
    my ($self, %options) = @_;

    if ( !defined($self->{vault_config}->{url}) || $self->{vault_config}->{url} eq '') {
        $self->{logger}->writeLogInfo("Vault url is missing from configuration.");
        $self->{vault_config}->{url} = '127.0.0.1';
    }
    if ( !defined($self->{vault_config}->{port}) || $self->{vault_config}->{port} eq '') {
        $self->{logger}->writeLogInfo("Vault port is missing from configuration.");
        $self->{vault_config}->{port} = '443';
    }

    # Normally, the role_id and secret_id data are encrypted using AES wit the following information:
    # firstKey = APP_SECRET (environment variable)
    # secondKey = 'salt' (hashing) key given by vault.json configuration file
    # both are base64 encoded
    if ( !defined($self->{vault_config}->{salt}) || $self->{vault_config}->{salt} eq '') {
        $self->{logger}->writeLogError("Vault environment does not seem complete: 'salt' attribute missing from "
            . $self->{config_file}
            . ". 'role_id' and 'secret_id' won't be decrypted, so they'll be used as they're stored in the vault config file.");
        $self->{crypted_credentials} = 0;
        $self->{hash_key} = '';
    } else {
        $self->{hash_key} = $self->{vault_config}->{salt}; # key for sha3-512 hmac
    }

    if ( !defined($ENV{'APP_SECRET'}) || $ENV{'APP_SECRET'} eq '' ) {
        $self->{logger}->writeLogError("Vault environment does not seem complete. 'APP_SECRET' environment variable missing."
            . " 'role_id' and 'secret_id' won't be decrypted, so they'll be used as they're stored in the vault config file.");
        $self->{crypted_credentials} = 0;
        $self->{encryption_key} = '';
    } else {
        $self->{encryption_key} = $ENV{'APP_SECRET'}; # key for aes-256-cbc
    }

    return 1;
}

sub authenticate {
    my ($self) = @_;

    my @ids_list = ('role_id', 'secret_id');
    # initial value: assuming the role and secret id might not be encrypted
    my ($role_id, $secret_id) = map $self->{vault_config}->{$_}, @ids_list;

    # now if credentials are encrypted
    if ($self->{crypted_credentials}) {
        ($role_id, $secret_id) = map
            centreon::vmware::common::aes256_decrypt(
                'data'       => $self->{vault_config}->{$_},
                'app_secret' => $self->{encryption_key},
                'logger'     => $self->{logger}
            ), @ids_list;
        $self->{logger}->writeLogDebug("role_id and secret_id have been decrypted.");
    }
    my $post_data = "role_id=$role_id&secret_id=$secret_id";

    # Authenticate to get the token
    my $url = "https://" . $self->{vault_config}->{url} . ":" . $self->{vault_config}->{port} . "/v1/auth/approle/login";
    $self->{logger}->writeLogDebug("Authenticating to the vault server at URL: $url");
    $self->{curl_easy}->setopt( CURLOPT_URL, $url );

    my $auth_result_json;
    # to get more details (in STDERR)
    #$self->{curl_easy}->setopt(CURLOPT_VERBOSE, 1);
    $self->{curl_easy}->setopt(CURLOPT_POST, 1);
    $self->{curl_easy}->setopt(CURLOPT_POSTFIELDS, $post_data);
    $self->{curl_easy}->setopt(CURLOPT_POSTFIELDSIZE, length($post_data));
    $self->{curl_easy}->setopt(CURLOPT_WRITEDATA(), \$auth_result_json);

    eval {
        $self->{curl_easy}->perform();
    };
    if ($@) {
        $self->{logger}->writeLogError("Error while authenticating to the vault: " . $@);
        return undef;
    }

    $self->{logger}->writeLogInfo("Authentication to the vault passed." );

    my $auth_result_obj = centreon::vmware::common::transform_json_to_object($auth_result_json);
    if (defined($auth_result_obj->{error_message})) {
        $self->{logger}->writeLogError("Error while decoding JSON '$auth_result_json'. Message: "
                . $auth_result_obj->{error_message});
        return undef;
    }

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

    $self->{logger}->writeLogInfo("Authenticating worked. Token valid until "
        . localtime($self->{auth}->{expiration_epoch}));

    return 1;
}

sub is_token_still_valid {
    my ($self) = @_;
    if (
            !defined($self->{auth})
            || !defined($self->{auth}->{token})
            || $self->{auth}->{token} eq ''
            || $self->{auth}->{expiration_epoch} <= time()
    ) {
        $self->{logger}->writeLogInfo("The token has expired or is invalid.");
        return undef;
    }
    $self->{logger}->writeLogDebug("The token is still valid.");
    return 1;
}

sub get_secret {
    my ($self, $secret) = @_;

    # if vault not enabled, return the secret unchanged
    return $secret if ( ! $self->{enabled});

    my ($secret_path, $secret_name) = $secret =~ $VAULT_PATH_REGEX;
    if (!defined($secret_path) || !defined($secret_name)) {
        $self->{logger}->writeLogInfo("A string given to get_secret does not look like a secret. Using it as a plain text credential?");
        return $secret;
    }
    $self->{logger}->writeLogDebug("Secret path: $secret_path - Secret name: $secret_name");

    if (!defined($self->{auth}) || !$self->is_token_still_valid() ) {
        $self->authenticate() or return $secret;
    }

    # prepare the GET statement
    my $get_result_json;
    my $url = "https://" . $self->{vault_config}->{url} . ":" . $self->{vault_config}->{port} . "/v1/" . $secret_path;
    $self->{logger}->writeLogDebug("Requesting URL: $url");

    #$self->{curl_easy}->setopt( CURLOPT_VERBOSE, 1 );
    $self->{curl_easy}->setopt( CURLOPT_URL, $url );
    $self->{curl_easy}->setopt( CURLOPT_POST, 0 );
    $self->{curl_easy}->setopt( CURLOPT_WRITEDATA(), \$get_result_json );
    $self->{curl_easy}->setopt( CURLOPT_HTTPHEADER(), ["X-Vault-Token: " . $self->{auth}->{token}]);

    eval {
        $self->{curl_easy}->perform();
    };
    if ($@) {
        $self->{logger}->writeLogError("Error while getting a secret from the vault: " . $@);
        return $secret;
    }

    $self->{logger}->writeLogDebug("Request passed.");

    # the result is a json string, convert it into an object
    my $get_result_obj = centreon::vmware::common::transform_json_to_object($get_result_json);
    if (defined($get_result_obj->{error_message})) {
        $self->{logger}->writeLogError("Error while decoding JSON '$get_result_json'. Message: "
                . $get_result_obj->{error_message});
        return $secret;
    }
    $self->{logger}->writeLogDebug("Request id is " . $get_result_obj->{request_id});

    # .data.data will contain the stored macros
    if ( !defined($get_result_obj->{data})
            || !defined($get_result_obj->{data}->{data})
            || !defined($get_result_obj->{data}->{data}->{$secret_name}) ) {
        $self->{logger}->writeLogError("Could not get secret '$secret_name' from path '$secret_path' from the vault. Enable debug for more details.");
        $self->{logger}->writeLogDebug("Response: " . $get_result_json);
        return $secret;
    }
    $self->{logger}->writeLogInfo("Secret '$secret_name' from path '$secret_path' retrieved from the vault.");
    return $get_result_obj->{data}->{data}->{$secret_name};
}

1;

__END__

=head1 NAME

Centreon Vault password manager

=head1 SYNOPSIS

Allows to retrieve secrets (usually username and password) from a HashiCorp vault compatible API.

    use centreon::vmware::logger;
    use centreon::script::centreonvault;
    my $vault = centreon::script::centreonvault->new(
        (
            'logger'      => centreon::vmware::logger->new(),
            'config_file' =>  '/var/lib/centreon/vault/vault.json'
        )
    );
    my $password = $vault->get_secret('secret::hashicorp_vault::mypath/to/mysecrets::password');

=head1 METHODS

=head2 new(\%options)

Constructor of the vault object.

%options must provide:

- logger: an object of the centreon::vmware::logger class.

- config_file: full path and file name of the Centreon Vault JSON config file.

The default config_file path should be '/var/lib/centreon/vault/vault.json'.
The expected file format for Centreon Vault is:

    {
      "name": "hashicorp_vault",
      "url": "vault-server.my-domain.com",
      "salt": "<base64 encoded(<32 bytes long key used to hash the encrypted data)>",
      "port": 443,
      "root_path": "vmware_daemon",
      "role_id": "<base64 encoded(<iv><hmac_hash><encrypted_role_id>)",
      "secret_id": "<base64 encoded(<iv><hmac_hash><encrypted_secret_id>)"
    }

=head2 get_secret($secret)

Returns the secret stored in the Centreon Vault at the given path.
If the format of the secret does not match the regular expression
C</^secret::hashicorp_vault::([^:]+)::(.+)$/>
or in case of any failure in the process, the method will return the secret unchanged.

=cut
