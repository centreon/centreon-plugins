#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::RealBin/../../../src";
use centreon::plugins::statefile;

# Mock options class
{
    package MockOptions;
    sub new { bless {}, shift }
    sub add_options { }
    sub add_help { }
}

sub process_test {
    my ($dir, $filename, $suffix, $format, $crypt_algo, $crypt_key) = @_;

    # Create mock objects
    my $options = MockOptions->new();
    my $expected_statefile = $dir . '/' . $filename . $suffix;
    unlink $expected_statefile if (-e $expected_statefile);

    # Options to create a statefile object
    $options->{statefile_dir}       = $dir;
    $options->{statefile_suffix}    = $suffix;
    $options->{statefile_format}    = $format;
    $options->{statefile_cipher}    = $crypt_algo;
    $options->{statefile_key}       = $crypt_key;

    # Test object creation
    my $statefile;
    eval { $statefile = centreon::plugins::statefile->new(options => $options) };
    ok(!$@, 'Object creation without errors');

    $statefile->check_options(option_results => $options);

    # Test if the object is blessed correctly
    is(ref($statefile), 'centreon::plugins::statefile', 'Object is of correct class');

    # Test if the object has the expected attributes
    can_ok($statefile, qw(new check_options read write get get_string_content error));

    # Try a first read to initiate a session
    is( $statefile->read(statefile => 'test_statefile'), 0, 'State file read.' );
    ok(!$@, 'Read method executed without errors');

    # Test write method
    is( $statefile->write(data => { some_key => 'some_value' }), 1, 'State file written.' );
    ok(!$@, 'Write method executed with plain text data without errors');

    # Test if the statefile was created
    ok(-e $expected_statefile, 'File ' . $expected_statefile . ' exists');


    # Test read method
    eval { $statefile->read(statefile => 'test_statefile') };
    ok(!$@, 'Read method executed without errors');

    # Test get method
    my $value = $statefile->get(name => 'some_key');
    #use Data::Dumper;
    #is($value, 'some_value', 'Get method with plain text data retrieves correct value' . Dumper($statefile->{datas}));
    is($value, 'some_value', 'Get method with plain text data retrieves correct value');

    # Test get_string_content method
    my $string_content = $statefile->get_string_content();
    like($string_content, qr/some_key/, 'Get plain text string content method works correctly');

    # cleanup the mess
    unlink $expected_statefile;
}

sub main {
    process_test('/tmp', 'test_statefile', '_plaintext', 'json', undef, undef);
    process_test('/tmp', 'test_statefile', '_encrypted', 'json', 'AES', 'mellon');
    done_testing();
}

main();


