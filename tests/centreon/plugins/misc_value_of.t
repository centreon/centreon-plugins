use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings echo => 1;
use FindBin;
use lib "$FindBin::RealBin/../../../src";
use centreon::plugins::misc;

# Test centreon::plugins::misc::value_of function !

my ($oldout, $olderr);

# For reval don't pollute test output when we pass invalid values
# silence(1): we save old STDOUT/STDERR and replace them by /dev/null
# silence(0): we restore old STDOUT/STDERR
sub silence($) {
    my ($silent) = @_;

    if ($silent) {
        open $oldout, ">&", \*STDOUT;
        open $olderr, ">&", \*STDERR;
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
    } else {
        open STDOUT, ">&", $oldout;
        open STDERR, ">&", $olderr;
    }
}

sub test_value_of {
    my ($var, @tests, $result);


    # test Hash
    $var = { 'test' => 'ok',
             'test2' => undef,
             'test3', => ''
           };
    @tests = ( { expression => '->{test}',  expected => 'ok', msg => 'Simple hash 1' }, # existing key, return value
               { expression => '->{test2}', expected => 'default', msg => 'Simple hash 2' }, # existing key with undef value, return default
               { expression => '->{test3}', expected => '', msg => 'Simple hash 3' }, # existing key with '' value, return value
               { expression => '->{test4}', expected => 'default', msg => 'Simple hash 4' }, # non existing key, return default
               { expression => '->{\'test\'}', expected => 'ok', msg => 'Simple hash 5' } ); # existing key, return value

    is(centreon::plugins::misc::value_of($var, $_->{expression}, "default"), $_->{expected}, $_->{msg})
        foreach @tests;


    # test Array
    $var = [ 'ok', '', undef ];
    @tests = ( { expression => '->[0]', expected => 'ok', msg => 'Simple array 1' }, # existing index, return value
               { expression => '->[1]', expected => '', msg => 'Simple array 2' }, # existing index with '' value, return value
               { expression => '->[2]', expected => 'default', msg => 'Simple array 3' }, # existing index with undef value, return default
               { expression => '->[3]', expected => 'default', msg => 'Simple array 4' } ); # non existing index, return default

    is(centreon::plugins::misc::value_of($var, $_->{expression}, "default"), $_->{expected}, $_->{msg})
        foreach @tests;

    # test undef value
    undef $var;
    @tests = ( { expression => '', expected => 'default', msg => 'Simple undef 1' }, # undef value, return default
               { expression => '->{test}', expected => 'default', msg => 'Simple undef 2' }, # undef value, return default
               { expression => '->[0]', expected => 'default', msg => 'Simple undef 3' }, # undef value, return default
               { expression => undef, expected => 'default', msg => 'Simple undef 4' } ); # undef value, return default
    is(centreon::plugins::misc::value_of($var, $_->{expression}, "default"), $_->{expected}, $_->{msg})
        foreach @tests;

    # test text
    $var = "text";
    @tests = ( { expression => '', expected => 'text', msg => 'Simple scalar 1' }, # text value, return value
               { expression => '->{test}', expected => 'default', msg => 'Simple scalar 2' }, # invalid expression, return default
               { expression => '->[0]', expected => 'default', msg => 'Simple scalar 3' } ); # invalid expression, return default

    is(centreon::plugins::misc::value_of($var, $_->{expression}, "default"), $_->{expected}, $_->{msg})
        foreach @tests;

    # test number
    $var = 1;
    @tests = ( { expression => '', expected => 1, msg => 'Simple scalar 4' }, # number value, return value
               { expression => '->{test}', expected => 999, msg => 'Simple scalar 5' }, # invalid expression, return default
               { expression => '->[0]', expected => 999, msg => 'Simple scalar 6' } ); # invalid expression, return default


    is(centreon::plugins::misc::value_of($var, $_->{expression}, 999), $_->{expected}, $_->{msg})
        foreach @tests;


    # test complex structure
    $var = [ { 'a' => [ { 'complex' => [ { 'structure' => [ 'ok', -1, undef ] } ] } ] } ];
    @tests = ( { expression => '->[0]->{a}->[0]->{complex}->[0]->{structure}->[0]', expected => 'ok', msg => 'Complex structure 1' }, # existing expression, return value
               { expression => '->[0]->{a}->[0]->{complex}->[0]->{structure}->[1]', expected => -1, msg => 'Complex structure 2' }, # existing expression, return value
               { expression => '->[0]->{a}->[0]->{complex}->[0]->{structure}->[2]', expected => 'default', msg => 'Complex structure 3' }, # existing expression with undef value, return default
               { expression => '->[0]->{a}->[0]->{complex}->[0]->{structure}->[3]', expected => 'default', msg => 'Complex structure 4' }, # non existing expression, return default
               { expression => '->[10]->{c}->{toto}', expected => 'default', msg => 'Complex structure 5' }, # non existing expression, return default
               { expression => '->{bla}->{bla}->[10]', expected => 'default', msg => 'Complex structure 6' }, # non existing expression, return default
               { expression => '-><--><-->', expected => 'default', msg => 'Complex structure 7' }, # invalid expression, return default
               { expression => '[20]', expected => 'default', msg => 'Complex structure 8' } ); # invalid expression, return default

    is(centreon::plugins::misc::value_of($var, $_->{expression}, "default"), $_->{expected}, $_->{msg})
        foreach @tests;


    $var = '$_@a&!?';
    @tests = ( { expression => '->{a$ze@eaz}', expected => 'default', msg => 'Dangerous characters 1' }, # invalid expression, return default
               { expression => '->[a$ze@eaz]', expected => 'default', msg => 'Dangerous characters 2' }, # invalid expression, return default
               { expression => '->[0]->{a$ze@eaz}', expected => 'default', msg => 'Dangerous characters 3' }, # invalid expression, return default
               { expression => '->{a$ze@eaz}->[0]', expected => 'default', msg => 'Dangerous characters 4' }, # invalid expression, return default
               { expression => '->[0]->{a$ze@eaz}->[0]', expected => 'default', msg => 'Dangerous characters 5' }, # invalid expression, return default
               { expression => '$_', expected => 'default', msg => 'Dangerous characters 6' }, # invalid expression, return default
               { expression => '@_', expected => 'default', msg => 'Dangerous characters 7' } ); # invalid expression, return default

    foreach my $test (@tests) {
        silence(1);
        $result = centreon::plugins::misc::value_of($var, $test->{expression}, "default");
        silence(0);
        is($result, $test->{expected}, $test->{msg});
    }

    undef $var;
    $result = centreon::plugins::misc::value_of($var, '->[0]', [ 'un array' ]); # return default value as array
    ok(ref $result eq 'ARRAY' && @{$result} && $result->[0] eq 'un array', 'Default value is an array');

    $result = centreon::plugins::misc::value_of($var, '->{non}', { 'key' => 'value' }); # return default value as hash
    ok(ref $result eq 'HASH' && $result->{key} eq 'value', 'Default value is a hash');
}

test_value_of();
done_testing();
