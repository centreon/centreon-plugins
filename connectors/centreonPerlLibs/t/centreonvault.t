#!/usr/bin/perl
use strict;
use warnings;
use Test2::V0;
use Test2::Plugin::NoWarnings echo => 1;
use Test2::Tools::Compare qw{is like match};
use Net::Curl::Easy qw(:constants);
use Data::Dumper;

use FindBin;
use lib "$FindBin::RealBin/../src";

use centreon::common::centreonvault;
use centreon::common::logger;
use JSON::XS;

my $vault;
my $global_logger = centreon::common::logger->new();
#$global_logger->file_mode("/dev/null");
# this is an exemple of configuration for vault, the decrypted role_id/secret_id both are "String-to-encrypt"
my $default_app_secret = 'SGVsbG8gd29ybGQsIGRvZywgY2F0LCBwdXBwaWVzLgo=';
my $vault_config_hash = {
    "name"      => "default",
    "url"       => "localhost",
    "port"      => 443,
    "root_path" => "path",
    "role_id"   => "4vOkzIaIJ7yxGWmysGVYY9sYHDyDM1nEv1++jSx9eAHpj83J6aIjE5SPvvpF6kBu3JeFga7o6DDS2yC7jVPAwXsWiur+KUOQncPq0JtjiFojr9YkrO8x1w1dmQFq/RqYV/S/kUare8z6r6+RnAxwsA==",
    "secret_id" => "4vOkzIaIJ7yxGWmysGVYY9sYHDyDM1nEv1++jSx9eAHpj83J6aIjE5SPvvpF6kBu3JeFga7o6DDS2yC7jVPAwXsWiur+KUOQncPq0JtjiFojr9YkrO8x1w1dmQFq/RqYV/S/kUare8z6r6+RnAxwsA==",
    "salt"      => "U2FsdA==" }; # for now the salt is not used, it will be used to check the data where correctly decrypted.

sub test_new {
    my @test_data = (
        { 'logger' => undef, 'config_file' => undef, 'test' => '$error_message =~ /FATAL: No logger given to the constructor/' },
        { 'logger' => $global_logger, 'config_file' => undef, 'test' => '$vault->{enabled} == 0' },
        { 'logger' => $global_logger, 'config_file' => 'does_not_exist.json', 'test' => '$vault->{enabled} == 0' }
    );

    for my $i (0 .. $#test_data) {
        my $logger = $test_data[$i]->{logger};
        my $config_file = $test_data[$i]->{config_file};
        my $test = $test_data[$i]->{test};


        #print("Test $i with logger " . Dumper($logger) ."\n");
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
    my $old_app_secret = $ENV{'APP_SECRET'};
    $ENV{'APP_SECRET'} = $default_app_secret;
    $vault = centreon::common::centreonvault->new(
        (
            'logger'      => $global_logger,
            'config_file' => $vault_config_hash
        )
    );

    is($vault->extract_and_decrypt(('data' => $vault_config_hash->{secret_id})), 'String-to-encrypt', 'extract_and_decrypt() worked');
    # I encrypted the string "String-to-encrypt" from the C++ implementation, and set it to secret_id and role_id
    # the key to decrypt is set as an environment variable.
    # the salt can used to encrypt again the data, so the script can be sure the decryption worked correctly, but this function is not implemented yet.
    $ENV{'APP_SECRET'} = $old_app_secret;
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
    no warnings 'prototype';
    $vault = centreon::common::centreonvault->new(
        (
            'logger'      => $global_logger,
            'config_file' => $vault_config_hash
        )
    );
    print "opt : " . CURLOPT_WRITEDATA . "\n";

    my $mock = mock 'Net::Curl::Easy'; # is from Test2::Tools::Mock, included by Test2::V0
    # @TODO: we can find the link to the variable in the setopt when the opt number is the good one
    #we can either set the value (the effective mock action) in the setopt or in the perform, but the perform will force use to store that value somewhere temporaly.
    #

    my $required_option = {
        CURLOPT_POST()          => { result => 1, detail => 'the http request should be POST.' },
        CURLOPT_POSTFIELDS()    => { result => 'role_id=String-to-encrypt&secret_id=String-to-encrypt', detail => 'postfields are correct' },
        CURLOPT_POSTFIELDSIZE() => { result => 53, detail => 'post field size is set.' },
        CURLOPT_URL()           => {result => 'https://localhost:443/v1/auth/approle/login', detail => 'target url was set'},

    };

    $mock->override('perform' => sub($) {
        # this is not what is done in reallity, but it's easier for mocking purpose.
        if (keys %{$required_option}) {
            fail "Some curl parameter where not correctly set : " .join(keys %{$required_option}, ', ') . "\n";
        }
    },
        'setopt'              => sub($$$) {
            my $self = shift;
            print Dumper(@_);

            # the real workhorse of the lib, we must have an hash %required_option present before this.
            # this sub check in the hash if the option is correctly set, and delete it from the hash if it's correct.
            # when doing perform, all options should have been set. So if there is still element in the hash, it is an error, as some parameter where not correctly set.

            if ($_[0] == CURLOPT_WRITEDATA) {
                # ${} allow to derefecence the variable given, as it's given in the form \$var to curl.
                ${$_[1]} = '{"auth":{"lease_duration":"13455", "client_token":"ImAToken"}}';
                return;
            }
            if ($required_option->{$_[0]}) {
                print "checking " . $_[1] . "\n";
                is($_[1], $required_option->{$_[0]}->{result}, $required_option->{$_[0]}->{detail});
                delete($required_option->{$_[0]});
            }
            else {
                print "$_[0] is not the same as \n";
                print Dumper($required_option);
            }
        }
    );

    $vault->authenticate();

}

sub main {
    my $old_app_secret = $ENV{'APP_SECRET'};
    $ENV{'APP_SECRET'} = $default_app_secret;
    #test_new();
    #test_decrypt();
    #test_transform_json_to_object();
    test_authenticate();
    $ENV{'APP_SECRET'} = $old_app_secret;

    done_testing();
}

&main;