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

    $self->init();
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    die "FATAL: No logger given to the constructor." if ( !defined($self->{logger}) );
    $self->{logger}->writeLogFatal("No config file given to the constructor.") if ( !defined($self->{config_file}));
}

sub check_configuration {
    my ($self, %options) = @_;

    if ( !defined($self->{vault_config}->{url}) or $self->{vault_config}->{url} eq '') {
        $self->{logger}->writeLogInfo("Vault url is missing from configuration.");
        $self->{vault_config}->{url} = '127.0.0.1';
    }
    if ( !defined($self->{vault_config}->{port}) or $self->{vault_config}->{port} eq '') {
        $self->{logger}->writeLogInfo("Vault port is missing from configuration.");
        $self->{vault_config}->{port} = '443';
    }
}

sub init {
    my ($self, %options) = @_;

    $self->check_options();

    # Since this class is used, we assume that credentials are encrypted. It may be reconsidered later.
    $self->{credentials_are_encrypted} = 1;

    # check if the following information is available
    $self->{logger}->writeLogDebug("Reading Vault configuration from file " . $self->{config_file} . ".");
    $self->{vault_config} = centreon::vmware::common::parse_json_file( 'json_file' => $self->{config_file} ) or return 0;

    $self->check_configuration();

    $self->{logger}->writeLogDebug("Vault configuration read. Name: " . $self->{vault_config}->{name} . ". Url: " . $self->{vault_config}->{url} . ".");

    # Normally, the role-id and secret-id data are encrypted using AES wit the following information:
    # firstKey = APP_SECRET (environment variable)
    # secondKey = clé 'salt' fournie dans le fichier de configuration vault.json
    # both are base64 encoded
    if ( !defined($self->{vault_config}->{salt}) or $self->{vault_config}->{salt} eq '') {
        $self->{logger}->writeLogError("Vault environment does not seem complete: 'salt' attribute missing from " . $self->{config_file} . ". 'role-id' and 'secret-id' won't be decrypted, so they'll be uses as they're stored in the vault config file.");
        $self->{credentials_are_encrypted} = 0;
    }

    if ( !defined($ENV{'APP_SECRET'}) or $ENV{'APP_SECRET'} eq '' ) {
        $self->{logger}->writeLogError("Vault environment does not seem complete. 'APP_SECRET' environment variable missing. 'role-id' and 'secret-id' won't be decrypted, so they'll be used as they're stored in the vault config file.");
        $self->{credentials_are_encrypted} = 0;
    }

    $self->prepare_decryption() if ($self->{credentials_are_encrypted} == 1);
    # Now we're ready to decrypt the vault credentials, but we'll do that only when necessary to avoid keeping them in memory
    $self->{curl_easy} = Net::Curl::Easy->new();
    $self->{curl_easy}->setopt( CURLOPT_USERAGENT, "Centreon VMware daemon's centreonvault.pm");

    $self->authenticate() or return 0;

    return 1;
}


sub prepare_decryption {
    my ($self) = @_;

    $self->{encryption_key} = $ENV{'APP_SECRET'};            # for aes-256-cbc
    $self->{hash_key}       = $self->{vault_config}->{salt}; # for sha3-512

    return 1;
}

sub extract_and_decrypt {
    my ($self, %options) = @_;

    my $input = decode_base64($options{data});
    $self->{logger}->writeLogDebug("data to extract and decrypt: '" . $options{data} . "'");

    #Todo: get the IV length
    my $iv_length = 16;
    # extract the IV, the hashed data, the encrypted data
    my $iv             = substr($input, 0, $iv_length);     # initialization vector
    my $hashed_data    = substr($input, $iv_length, 64);    # hmac of the original data, for integrity control
    my $encrypted_data = substr($input, $iv_length + 64);   # data to decrypt

    # create the AES object
    $self->{logger}->writeLogDebug(
            "Creating the AES decryption object for initialization vector (IV) of length "
            . length($iv) . "B, key of length " . length($self->{encryption_key}) . "B."
    );
    my $cipher;
    eval {
        $cipher = Crypt::OpenSSL::AES->new(
            decode_base64( $self->{encryption_key} ),
            {
                'cipher'  => 'AES-256-CBC',
                'iv'      => $iv,
                'padding' => 1
            }
        );
    };
    if ($@) {
        $self->{logger}->writeLogFatal("There was an error while creating the AES object: " . $@);
        return 0;
    }

    # decrypt
    $self->{logger}->writeLogDebug("Decrypting the data of length " . length($encrypted_data) . "B.");
    my $decrypted_data;
    eval {$decrypted_data = $cipher->decrypt($encrypted_data);};
    if ($@) {
        $self->{logger}->writeLogFatal("There was an error while decrypting one of the AES-encrypted data: " . $@);
    }

    #Todo: make sure the decrypted data produces the same hash as in $hashed_data but the right hmac function could not be found yet
    #my $hashed_decrypted_data;
    #eval {$hashed_decrypted_data = sha3_512($decrypted_data, $self->{hash_key});};
    #if ($@) {
    #    $self->{logger}->writeLogFatal("There was an error while calculating the : " . $@);
    #}

    #if ($hashed_decrypted_data ne $hashed_data) {
    #    $self->{logger}->writeLogDebug("There was an error, the hmac checksums do not match ('$hashed_decrypted_data' vs '$hashed_data')");
    #}
    return $decrypted_data;
}

sub authenticate {
    my ($self) = @_;

    my $encrypted_role_id   = $self->{vault_config}->{role_id};
    my $encrypted_secret_id = $self->{vault_config}->{secret_id};

    # initial value: assuming the role and secret id might not be encrypted
    my ($plain_role_id, $plain_secret_id) = ($encrypted_role_id, $encrypted_secret_id);

    # Then decrypt using https://github.com/perl-openssl/perl-Crypt-OpenSSL-AES
    # keep the decrypted data in local variables so that they stay in memory for as little time as possible
    if ($self->{credentials_are_encrypted} == 1) {
        $self->{logger}->writeLogDebug("Decrypting the credentials needed to authenticate to the vault.");
        $plain_role_id   = $self->extract_and_decrypt( ('data' => $encrypted_role_id ));
        $plain_secret_id = $self->extract_and_decrypt( ('data' => $encrypted_secret_id ));
        $self->{logger}->writeLogDebug("role_id and secret_id have been decrypted.");
    }

    # Authenticato to get the token
    my $url = "https://" . $self->{vault_config}->{url} . ":" . $self->{vault_config}->{port} . "/v1/auth/approle/login";
    $self->{logger}->writeLogDebug("Authenticating to the vault server at URL: $url");
    $self->{curl_easy}->setopt( CURLOPT_URL, $url );

    my $post_data = "role_id=$plain_role_id&secret_id=$plain_secret_id";
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
        return 0;
    }

    $self->{logger}->writeLogInfo("Authentication to the vault passed." );

    my $auth_result_obj = centreon::vmware::common::transform_json_to_object($auth_result_json);

    # store the token (.auth.client_token) and its expiration date (current date + .lease_duration)
    my $expiration_epoch = -1;
    my $lease_duration = $auth_result_obj->{auth}->{lease_duration};
    if ( defined($lease_duration)
            and $lease_duration =~ /\d+/
            and $lease_duration > 0 ) {
        $expiration_epoch = time() + $lease_duration;
    }
    $self->{auth} = {
        'token'            => $auth_result_obj->{auth}->{client_token},
        'expiration_epoch' => $expiration_epoch
    };

    #Todo: translate epoch to human readable date
    $self->{logger}->writeLogInfo("Authenticating worked. Token valid until " . $self->{auth}->{expiration_epoch});

    return 1;
}

sub is_token_still_valid {
    my ($self) = @_;
    if (
            !defined($self->{auth})
            or !defined($self->{auth}->{token})
            or $self->{auth}->{token} eq ''
            or $self->{auth}->{expiration_epoch} <= time()
    ) {
        $self->{logger}->writeLogInfo("The token expired or invalid.");
        return 0;
    }
    $self->{logger}->writeLogDebug("The token is still valid.");
    return 1;
}

sub is_password_a_vault_secret {
    my ($self, $password) = @_;

    return 1 if ($password =~ $VAULT_PATH_REGEX);
    return 0;
}

sub get_secret {
    my ($self, $path) = @_;

    my $secret_path = $path;

    # reminder: $VAULT_PATH_REGEX = /^secret::hashicorp_vault::([^:]+)::(.+)$/
    my ($root_path, $secret_name) = $secret_path =~ $VAULT_PATH_REGEX;
    if (!defined($root_path) or !defined($secret_name)) {
        $self->{logger}->writeLogDebug("A string given to get_secret does not look like a secret. Using it as a plain text password.");
        return $secret_path;
    }
    $self->{logger}->writeLogDebug("Root path: $root_path - Secret name: $secret_name");

    $self->authenticate() if ( !$self->is_token_still_valid() );
    # prepare the GET statement
    my $get_result_json;
    my $url = "https://" . $self->{vault_config}->{url} . ":" . $self->{vault_config}->{port} . "/v1/" . $root_path;
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
        return 0;
    }

    $self->{logger}->writeLogDebug("Request passed.");
    # request_id

    # the result is a json string, convert it into an object
    my $get_result_obj = centreon::vmware::common::transform_json_to_object($get_result_json);
    $self->{logger}->writeLogDebug("Request id is " . $get_result_obj->{request_id});

    # .data.data will contain the stored macros
    if (!defined($get_result_obj->{data}) or !defined($get_result_obj->{data}->{data}) or !defined($get_result_obj->{data}->{data}->{$secret_name})) {
        $self->{logger}->writeLogError("Could not get secret '$secret_name' from path '$root_path' from the vault.");
        return 'ERROR';
    }
    $self->{logger}->writeLogInfo("Secret '$secret_name' from path '$root_path' retrieved from the vault.");
    return $get_result_obj->{data}->{data}->{$secret_name};
}

1;

__END__

=head1 NAME

Centreon Vault password manager

=head1 SYNOPSIS

Centreon Vault password manager

To be used with an array containing keys/values saved in a secret path by resource

=head1 VAULT OPTIONS

=over 8

=item B<--vault-config>

The path to the file defining access to the Centreon vault (/etc/centreon-engine/centreonvault.json by default)

=back

=head1 DESCRIPTION

B<centreonvault>.

=cut
