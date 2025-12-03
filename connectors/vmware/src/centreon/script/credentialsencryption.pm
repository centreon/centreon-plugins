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

package centreon::script::credentialsencryption;

use strict;
use warnings;
use JSON::XS;
use MIME::Base64;
use Crypt::OpenSSL::AES;
use centreon::vmware::common;

my $ENCRYPTED_PATH_REGEX = qr/^encrypt::(.+)$/;

sub new {
    my ($class, %options) = @_;
    my $self  = bless \%options, $class;
    # mandatory options:
    # - logger: logger object
    # - config_file: path of a JSON Credentials encryption config file

    $self->{enabled} = 1;
    $self->{crypted_credentials} = 1;

    if ( !$self->init() ) {
        $self->{enabled} = 0;
        $self->{logger}->writeLogInfo("Something happened during init() method that makes Credentials encryption not usable. Ignore this if you don't use Credentials encryption.");
    }
    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->check_options() or return undef;

    # check if the following information is available
    $self->{logger}->writeLogDebug("Reading Engine context configuration from file " . $self->{config_file} . ".");
    my $config = centreon::vmware::common::parse_json_file( 'json_file' => $self->{config_file} );
    if (defined($config->{error_message})) {
        $self->{logger}->writeLogError("Error while parsing " . $self->{config_file} . ": "
            . $config->{error_message});
        return undef;
    }


    $self->check_configuration(%$config) or return undef;

    return 1;
}

sub check_options {
    my ($self, %options) = @_;

    if ( !defined($self->{logger}) ) {
        die "[credentialsencryption:check_options] FATAL: No logger given to the constructor. Credentials encryption cannot be used.";
    }
    if ( !defined($self->{config_file})) {
        $self->{logger}->writeLogError("No config file given to the constructor. Credentials encryption cannot be used.");
        return undef;
    }
    if ( ! -f $self->{config_file} ) {
        $self->{logger}->writeLogError("The given configuration file " . $self->{config_file}
            . " does not exist. Passwords won't be decrypted. Ignore this if you don't use Credentials encryption.");
        return undef;
    }

    return 1;
}

sub check_configuration {
    my ($self, %options) = @_;

    # Normally, the credentials data are encrypted using AES wit the following information:
    # firstKey = app_secret
    # secondKey = 'salt' (hashing) key given by engine-context.json configuration file
    # both are base64 encoded
    foreach my $expected_key('app_secret', 'salt') {
        if ( !defined($options{$expected_key}) || $options{$expected_key} eq '') {
            $self->{logger}->writeLogError("Credentials encryption environment does not seem complete: '$expected_key' "
                . "attribute missing from " . $self->{config_file} . "Credentials won't be decrypted, so they'll be used as they're stored in the config file.");
            $self->{crypted_credentials} = 0;
            return undef;
            # $self->{hash_key} = '';
        # } else {
        #     $self->{hash_key} = $self->{salt}; # key for sha3-512 hmac
        }
        $self->{logger}->writeLogDebug("Key $expected_key is defined int the config file. We may use it.");
        $self->{$expected_key} = $options{$expected_key};
    }

    return 1;
}

sub get_secret {
    my ($self, $secret) = @_;

    $self->{logger}->writeLogDebug("Is credentials encryption enabled? " . $self->{enabled} . " (1 => true, 0 => false).");
    # if the feature is not enabled, return the secret unchanged
    return $secret if ( ! $self->{enabled});

    my ($encrypted_secret) = $secret =~ $ENCRYPTED_PATH_REGEX;
    if (!defined($encrypted_secret)) {
        $self->{logger}->writeLogInfo("A string given to get_secret does not look like a secret. Using it as a plain text credential?");
        return $secret;
    }
    $self->{logger}->writeLogDebug("Secret to decrypt: " . centreon::vmware::common::obfuscate_secret($secret));
    my $decrypted_secret = centreon::vmware::common::aes256_decrypt(
        'data'       => $encrypted_secret,
        'app_secret' => $self->{app_secret},
        'logger'     => $self->{logger}
    );
    $self->{logger}->writeLogDebug("Decrypted secret: " . centreon::vmware::common::obfuscate_secret($decrypted_secret));
    return $decrypted_secret;
}

1;

__END__

=head1 NAME

Centreon Encrypted Credentials manager

=head1 SYNOPSIS

Allows to decrypt secrets (usually username and password).

    use centreon::vmware::logger;
    use centreon::script::credentialsencryption;
    my $decrypt = centreon::script::credentialsencryption->new(
        (
            'logger'      => centreon::vmware::logger->new(),
            'config_file' =>  '/etc/centreon-engine/engine-context.json'
        )
    );
    my $password = $decrypt->get_secret('encrypted::encrypted_password');

=head1 METHODS

=head2 new(%options)

Constructor of the decrypting object.

%options must provide:

- logger: an object of the centreon::vmware::logger class.

- config_file: full path and file name of the Centreon Engine context file (JSON).

The default config_file path is '/etc/centreon-engine/engine-context.json'.
The expected file format for Centreon Engine context is:

    {
        "app_secret": "<hexadecimal value of the AES encryption/decryption key>",
        "salt": "<base64 encoded(<32 bytes long key used to hash the encrypted data)>"
    }

=head2 get_secret($secret)

Returns the decrypted secret.
If the format of the secret does not match the regular expression
C</^encrypted::(.+)$/>
or in case of any failure in the process, the method will return the secret unchanged.

=cut
