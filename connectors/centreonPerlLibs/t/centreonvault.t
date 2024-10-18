#!/usr/bin/perl
use strict;
use warnings;
use Test2::V0;
use Test2::Plugin::NoWarnings echo => 1;
use Test2::Tools::Compare qw{is like match};
use Net::Curl::Easy qw(:constants);
use Data::Dumper qw(Dumper);
use Storable qw(dclone);
use FindBin;
use lib "$FindBin::RealBin/../src";

use centreon::common::centreonvault;
use centreon::common::logger;
use JSON::XS;


# this sub make an hash with all generic data used in the tests, and send back a hashref.
sub create_data_set {
    my $set = {};
    $set->{vault} = undef;
    $set->{logger} = centreon::common::logger->new();
    $set->{logger}->file_mode("/dev/null");

    # this is an exemple of configuration for vault.
    # I encrypted the string "String-to-encrypt" from the C++ implementation, and set it to secret_id and role_id
    # the key to decrypt should be set as an environment variable.
    # the salt can be used to encrypt again the data, so the script can be sure the decryption worked correctly, but this function is not implemented yet.
    $set->{default_app_secret} = 'SGVsbG8gd29ybGQsIGRvZywgY2F0LCBwdXBwaWVzLgo=';
    $set->{decryted_string} = 'String-to-encrypt';
    $set->{vault_config_hash} = {
        "name"      => "default",
        "url"       => "localhost",
        "port"      => 443,
        "root_path" => "path",
        "role_id"   => "4vOkzIaIJ7yxGWmysGVYY9sYHDyDM1nEv1++jSx9eAHpj83J6aIjE5SPvvpF6kBu3JeFga7o6DDS2yC7jVPAwXsWiur+KUOQncPq0JtjiFojr9YkrO8x1w1dmQFq/RqYV/S/kUare8z6r6+RnAxwsA==",
        "secret_id" => "4vOkzIaIJ7yxGWmysGVYY9sYHDyDM1nEv1++jSx9eAHpj83J6aIjE5SPvvpF6kBu3JeFga7o6DDS2yC7jVPAwXsWiur+KUOQncPq0JtjiFojr9YkrO8x1w1dmQFq/RqYV/S/kUare8z6r6+RnAxwsA==",
        "salt"      => "U2FsdA==" }; # for now the salt is not used, it will be used to check if the data where correctly decrypted.

    $set->{wrong_vault_config_hash} = {
        "name"      => "default",
        "url"       => "localhost",
        "port"      => 443,
        "root_path" => "path",
        "role_id"   => "WrongCryptedDataThatAESWontBeAbleToDecrypt==",
        "secret_id" => "WrongCryptedDataThatAESWontBeAbleToDecrypt==",
        "salt"      => "U2FsdA==" };

    # We will make multiples tests about authentication.
    # this is all the fields that should be set everytime.
    $set->{http}->{generic_auth_fields} = {
        CURLOPT_POST()          => { result => 1, detail => 'the http request should be POST' },
        CURLOPT_POSTFIELDS()    => { result => 'role_id=String-to-encrypt&secret_id=String-to-encrypt', detail => 'postfields are correct' },
        CURLOPT_POSTFIELDSIZE() => { result => 53, detail => 'post field size is set' },
        CURLOPT_URL()           => { result => 'https://localhost:443/v1/auth/approle/login', detail => 'target url was set' }, };
    # this is the token given by the API when the authentication work.
    $set->{http}->{"Vault_Token"} = "RandomAuthTokenGivenByVault";
    $set->{http}->{"vault_token_expiration"} = 13455;

    $set->{http}->{working_auth} = {
        (CURLOPT_WRITEDATA() => {
            result => '{"auth":{"lease_duration": "' . $set->{http}->{"vault_token_expiration"} . '",
            "client_token": "' . $set->{http}->{"Vault_Token"} . '"}}' }),
        %{$set->{http}->{generic_auth_fields}} };

    $set->{http}->{wrong_auth} = { (CURLOPT_WRITEDATA() => { result => '{' }), %{$set->{http}->{generic_auth_fields}} };

    return $set;

}

sub test_new {
    my $set = shift;
    my $vault = '';
    my @test_data = (
        { 'logger' => undef, 'config_file' => undef, 'test' => '$error_message =~ /FATAL: No logger given to the constructor/' },
        { 'logger' => $set->{logger}, 'config_file' => undef, 'test' => '$vault->{enabled} == 0' },
        { 'logger' => $set->{logger}, 'config_file' => 'does_not_exist.json', 'test' => '$vault->{enabled} == 0' }
    );

    for my $i (0 .. $#test_data) {
        my $logger = $test_data[$i]->{logger};
        my $config_file = $test_data[$i]->{config_file};
        my $test = $test_data[$i]->{test};

        eval {
            $vault = centreon::common::centreonvault->new(
                (
                    'logger'      => $logger,
                    'config_file' => $config_file
                )
            );
        };
        my $error_message = defined($@) ? $@ : '';
        ok(eval($test), "'$test' should be true");
    }
}

sub test_decrypt {
    my $set = shift;
    my $vault = centreon::common::centreonvault->new(
        (
            'logger'      => $set->{logger},
            'config_file' => $set->{vault_config_hash}
        )
    );

    is($vault->extract_and_decrypt(('data' => $set->{vault_config_hash}->{secret_id})), 'String-to-encrypt', 'extract_and_decrypt() worked');

}

sub test_transform_json_to_object {
    my $tests_cases = [
        {
            json   => '{"int": 12, "string": "A String with space", "array" : ["array-key", "string"]}',
            result => { "int" => 12, "string" => "A String with space", "array" => [ "array-key", "string" ] },
            detail => "simple json can be decoded as a perl object"
        },
        {
            json   => '"int": 12, "string": "A String with space", "array" : ["array-key", "string"]}',
            result => { "error_message" => match(qr/^Could not decode JSON from/) },
            detail => "invalid json should generate an error"
        },
        {
            json   => '',
            result => { "error_message" => match(qr/^Could not decode JSON from.*'. Reason:/) },
            detail => "empty json"
        },
        {
            json   => 'abcdef',
            result => { "error_message" => match(qr/^Could not decode JSON from/) },
            detail => "simple string json"
        },
        {
            json   => '{}',
            result => {},
            detail => "empty json brace should make an empty object"
        },
    ];

    for my $test (@$tests_cases) {
        is(centreon::common::centreonvault::transform_json_to_object($test->{json}), $test->{result}, $test->{detail});
    }

}

sub test_authenticate {
    my $set = shift;
    my $vault = centreon::common::centreonvault->new(
        (
            'logger'      => $set->{logger},
            'config_file' => $set->{vault_config_hash}
        )
    );

    my $mock_http_authenticate = mock_http($set->{http}->{working_auth});
    $vault->authenticate();
    is($vault->{auth}->{token}, $set->{http}->{"Vault_Token"}, "the token was correctly retrieved by authenticate()");
    is($vault->{auth}->{expiration_epoch}, time() + $set->{http}->{"vault_token_expiration"}, 'the expiration date is correct');
}

sub test_get_secret {
    my $set = shift;

    print("    When vault don't work we should send back the input token\n");
    my $vault = centreon::common::centreonvault->new(
        (
            'logger'      => $set->{logger},
            'config_file' => $set->{wrong_vault_config_hash}
        )
    );
    is($vault->get_secret("token"), "token", "role_id and secret_id can't be decrypted");

    $vault = centreon::common::centreonvault->new(
        (
            'logger'      => $set->{logger},
            'config_file' => $set->{vault_config_hash}
        )
    );
    my $clear_password = $vault->get_secret("token");
    is($vault->get_secret("token"), "token", "no authentication done because secret don't look like an hashicorp path");

    my $http_wrong_authentication = { (CURLOPT_WRITEDATA() => { result => '{' }), %{$set->{http}->{generic_auth_fields}} };
    my $mock_http_authenticate = mock_http($http_wrong_authentication);
    $clear_password = $vault->get_secret("secret::hashicorp_vault::SecretPathArg::secretNameFromApiResponse");
    is($vault->get_secret("token"), "token", "authentication didn't work because api send back an invalid authentication response");

    print("    When vault work we should send back the token retrieved by the API\n");
    my $http_get_secret_work = {
        CURLOPT_WRITEDATA()  => { result => '{"request_id": "ARandomString", "data": {"data" : {"secretNameFromApiResponse": "tokenGotFromApi"}}}' },
        CURLOPT_POST()       => { result => '0', detail => 'the http request should not be POST.' },
        CURLOPT_HTTPHEADER() => { result => [ "X-Vault-Token: " . $set->{http}->{"Vault_Token"} ], detail => 'the authentication header should be set.' },
        CURLOPT_URL()        => { result => 'https://localhost:443/v1/SecretPathArg', detail => 'target url was set' }
    };
    $mock_http_authenticate = mock_http( $set->{http}->{working_auth}, $http_get_secret_work);
    $clear_password = $vault->get_secret("secret::hashicorp_vault::SecretPathArg::secretNameFromApiResponse");
    is($clear_password, "tokenGotFromApi", "authentication worked, the token was correctly retrieved by get_secret() from the API");

}

sub main {
    my $set = create_data_set();

    my $old_app_secret = $ENV{'APP_SECRET'};
    $ENV{'APP_SECRET'} = $set->{default_app_secret};
    print "    Validate function not reaching external ressources\n";
    test_new($set);
    test_decrypt($set);
    test_transform_json_to_object($set);
    print "    Validate authentication and secret retrieving\n";
    test_authenticate($set);
    test_get_secret($set);
    $ENV{'APP_SECRET'} = $old_app_secret;

    done_testing();
}

# this sub is used to mock the Net::Curl::Easy object, to simulate the http request.
# the returned object should be stored in a local variable for the time of your test,
# as the mock will be enabled until the variable is deleted.
sub mock_http {
    # without dclone, the hash is modified by the test, and the second test using it will fail.
    my @mock_list = @{dclone(\@_)};
    my $required_option = shift(@mock_list);

    my $mock = mock 'Net::Curl::Easy'; # is from Test2::Tools::Mock, included by Test2::V0
    $mock->override('perform' => sub($) {
        # Normally this sub perform the actual http request and set the result to the variable given to setopt().
        # For test purpose, we set the mocked data in the setopt(), and only use perform() to check every parameter have correctly been set.
        # once we are sure all parameter where correctly set, we prepare the next request if there is any.
        # this is not what is done in reality, but it's easier for mocking purpose.
        if (keys %{$required_option}) {
            fail "[mock-curl] Some curl parameter where not correctly set : " . join(', ', keys(%{$required_option})) . "\n";
        }
        $required_option = shift(@mock_list);
    },
        # this sub is called for each parameter set to curl, we will check if the parameter is correctly set.
        'setopt'              => sub($$$) {
            my $self = shift; # we don't need this one
            my $opt_name = shift; # the option name, see Net::Curl::Easy (:constant) for the list of possible value.
            my $opt_value = shift;
            # the real workhorse of the lib, we must have an hashref $required_option = {} already declared.
            # this sub check in the hash if the option is correctly set, and delete it from the hash if it's correct.
            # when doing perform, all options should have been set. So if there is still element in the hash,
            # it is an error, as some parameter where not correctly set.
            # writedata is processed differently to send back the data to the caller.
            if ($opt_name == CURLOPT_WRITEDATA) {
                $$opt_value = $required_option->{$opt_name}->{result};
                delete($required_option->{$opt_name});
                return;
            }
            if ($required_option->{$opt_name}) {
                is($opt_value, $required_option->{$opt_name}->{result}, "[mock-curl] " . $required_option->{$opt_name}->{detail});
                delete($required_option->{$opt_name});
            } else {
                print(Dumper($required_option));
                fail("$opt_name is not present in the required_option hash.");

            }
        }
    );
    # we need to return the mocked object and to keep it, or the mock will be deleted and reverted.
    return $mock;

}
&main;