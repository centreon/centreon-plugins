use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is like match};
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use centreon::plugins::misc qw/convert_bytes_ng/;

sub test {

    my @tests = (
        {
            value            => undef,
            unit             => undef,
            pattern          => undef,
            expected_result  => 0,
            msg              => 'Test undef value'
        },
        {
            value            => '0',
            unit             => undef,
            pattern          => undef,
            expected_result  => 0,
            msg              => 'Test zero value'
        },
        {
            value            => '100',
            unit             => 'PP',
            pattern          => undef,
            expected_result  => 100,
            msg              => 'Test 100PP ( invalid unit )'
        },
        {
            value            => '1',
            unit             => 'Ki',
            pattern          => undef,
            expected_result  => 1024,
            msg              => 'Test with unit parameter (1 Ki)'
        },
        {
            value            => '1Ki',
            unit             => undef,
            pattern          => undef,
            expected_result  => 1024,
            msg              => 'Test 1Ki ( single value )'
        },

        {
            value            => '512',
            unit             => 'mb',
            pattern          => undef,
            expected_result  => 512 * 1000**2,
            msg              => 'Test 512mb'
        },
        {
            value            => '1',
            unit             => undef,
            pattern          => '^([\d\.]+)$',
            expected_result  => 1,
            msg              => 'Test with custom pattern 1'
        },
        {
            value            => '100 - MB',
            unit             => undef,
            pattern          => '^([\d\.]+)\s-\s([KMGTP])B?$',
            expected_result  => 100 * 1000**2,
            msg              => 'Test with custom pattern 2'
        },
        {
            value            => '1Gi',
            expected_result  => 1024**3,
            msg              => 'Test 1Gi'
        },
        {
            value            => '512Mi',
            expected_result  => 512 * 1024**2,
            msg              => 'Test 512Mi'
        },
        {
            value            => '29MB',
            expected_result  => 29 * 1000**2,
            msg              => 'Test 1MB'
        },
        {
            value            => '1GB',
            expected_result  => 1000**3,
            msg              => 'Test 1GB'
        },
        {
            value            => '1Kb',
            expected_result  => 1000,
            msg              => 'Test 1Kb'
        },
        {
            value            => '1G',
            expected_result  => 1000**3,
            msg              => 'Test 1G'
        },
        {
            value            => '1.5gi',
            expected_result  => int(1.5 * (1024**3)),
            msg              => 'Test 1.5gi'
        },
        {
            value            => '10',
            base             => 2048,
            expected_result  => 20480,
            msg              => 'Test with custom base'
        },
        {
            value            => 'invalid',
            expected_result  => 0,
            msg              => 'Test invalid string'
        }
    );

    for my $test (@tests) {
        my $result = convert_bytes_ng(value => $test->{value}, unit => $test->{unit}, pattern => $test->{pattern}, base => $test->{base});
        is($result, $test->{expected_result}, $test->{msg});
    }

}

test();
done_testing();

