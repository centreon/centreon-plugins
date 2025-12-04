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

package centreon::script::centreonsecrets;

use strict;
use warnings;
use JSON::XS;
use MIME::Base64;
use Crypt::OpenSSL::AES;
use Net::Curl::Easy qw(:constants);
use centreon::vmware::common qw(VAULT_PATH_REGEX ENCRYPTED_PATH_REGEX);
use centreon::script::centreonvault;
use centreon::script::credentialsencryption;


sub new {
    my ($class, %options) = @_;
    my $self  = bless \%options, $class;
    # mandatory options:
    # - logger: logger object
    # - opt_vault_config: path of a JSON vault config file
    # - opt_engine_context: path of a JSON engine context config file

    $self->{vault} = {};
    $self->{encryption} = {};
    $self->{enabled} = 1;
    $self->{crypted_credentials} = 1;

    if ( !$self->init() ) {
        $self->{enabled} = 0;
        $self->{logger}->writeLogInfo("Something happened during init() method that makes secrets object not usable.");
    }
    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->check_options() or return undef;

    # check if the following information is available
    $self->{logger}->writeLogDebug("Calling the vault object's constructor.");
    $self->{vault} = centreon::script::centreonvault->new(
        'logger'      => $self->{logger},
        'config_file' => $self->{opt_vault_config}
    );
    $self->{logger}->writeLogDebug("Calling the credentials encryption object's constructor.");
    $self->{encryption} = centreon::script::credentialsencryption->new(
        'logger'      => $self->{logger},
        'config_file' => $self->{opt_engine_context}
    );

    return 1;
}

sub check_options {
    my ($self, %options) = @_;

    if ( !defined($self->{logger}) ) {
        die "[centreonsecrets:check_options] FATAL: No logger given to the constructor. Secrets cannot be used.";
    }

    return 1;
}

sub check_configuration {
    my ($self, %options) = @_;

    return 1;
}

sub get_secret {
    my ($self, $secret) = @_;

    # if vault not enabled, return the secret unchanged
    return $secret if ( ! $self->{enabled});

    $self->{logger}->writeLogDebug("Secret to reveal: " . centreon::vmware::common::obfuscate_secret($secret));
    return $self->{vault}->get_secret($secret) if ($secret =~ VAULT_PATH_REGEX);
    return $self->{encryption}->get_secret($secret) if ($secret =~ ENCRYPTED_PATH_REGEX);

    $self->{logger}->writeLogDebug("The secret does not look like a secret. Using it as a plain text credential.");
    return $secret;
}

1;

__END__

=head1 NAME

Centreon secrets manager. Used as an interface to use either Centreon Vault or Centreon Credentials Encryption modules.

=head1 SYNOPSIS

Allows to retrieve secrets (usually username and password) from a Hashicorp vault compatible API of from Centreon
encrypted credentials.

    use centreon::vmware::logger;
    use centreon::script::centreonsecrets;
    my $vault = centreon::script::centreonsecrets->new(
        (
            'logger'             => centreon::vmware::logger->new(),
            'opt_vault_config'   => '/var/lib/centreon/vault/vault.json',
            'opt_engine_context' => '/etc/centreon-engine/engine-context.json'
        )
    );
    my $password_from_vault = $vault->get_secret('secret::hashicorp_vault::mypath/to/mysecrets::password');
    my $password_from_encryption = $vault->get_secret('encrypted::encrypted_password');

=head1 METHODS

=head2 new(\%options)

Constructor of the vault object.

%options must provide:

- C<logger>: an object of the centreon::vmware::logger class.

- C<opt_vault_config>: full path and file name of the Centreon Vault JSON config file.

- C<opt_engine_context>: full path and file name of the Centreon Engine context JSON file.

The default opt_vault_config path should be '/var/lib/centreon/vault/vault.json'.
The default opt_engine_context path should be '/etc/centreon-engine/engine-context.json'.
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

The expected file format for Centreon Engine context is:

    {
        "app_secret": "<hexadecimal value of the AES encryption/decryption key>",
        "salt": "<base64 encoded(<32 bytes long key used to hash the encrypted data)>"
    }

=head2 get_secret($secret)

Returns the encrypted secret or the secret stored in the Centreon Vault at the given path.
If the format of the secret matches none of the regular expressions
C</^secret::hashicorp_vault::([^:]+)::(.+)$/> or
C</^encrypted::(.+)$/>
or in case of any failure in the process, the method will return the secret unchanged.

=cut
