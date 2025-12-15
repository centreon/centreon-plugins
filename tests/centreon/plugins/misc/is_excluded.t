use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is like match};
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use centreon::plugins::misc;

sub test {

    my @tests = (
        {
            string           => undef,
            include_regexp   => undef,
            exclude_regexp   => undef,
            expected_boolean => 1,
            msg              => 'Test undef string with undef include and exclude regexp'
        },
        {
            string           => undef,
            include_regexp   => 'test',
            exclude_regexp   => undef,
            expected_boolean => 1,
            msg              => 'Test undef string with non-empty include and undef exclude regexp'
        },
        {
            string           => 'test',
            include_regexp   => undef,
            exclude_regexp   => undef,
            expected_boolean => 0,
            msg              => 'Test string with undef include and exclude regexp'
        },
        {
            string           => 'test',
            include_regexp   => '^t.*t$',
            exclude_regexp   => undef,
            expected_boolean => 0,
            msg              => 'Test string with include regexp and undef exclude regexp'
        },
        {
            string           => 'test',
            include_regexp   => undef,
            exclude_regexp   => '^t.*t$',
            expected_boolean => 1,
            msg              => 'Test string with undef include regex and non-empty exclude regexp'
        },
        {
            string           => '',
            include_regexp   => '',
            exclude_regexp   => '',
            expected_boolean => 0,
            msg              => 'Test empty string with empty include and exclude regexp'
        },
        {
            string           => '',
            include_regexp   => 'test',
            exclude_regexp   => '',
            expected_boolean => 1,
            msg              => 'Test empty string with non-empty include and empty exclude regexp'
        },
        {
            string           => 'test',
            include_regexp   => '',
            exclude_regexp   => '',
            expected_boolean => 0,
            msg              => 'Test string with empty include and exclude regexp'
        },
        {
            string           => 'test',
            include_regexp   => '^t.*t$',
            exclude_regexp   => '',
            expected_boolean => 0,
            msg              => 'Test string with include regexp and empty exclude regexp'
        },
        {
            string           => 'test',
            include_regexp   => '',
            exclude_regexp   => '^t.*t$',
            expected_boolean => 1,
            msg              => 'Test string with empty include regex and non-empty exclude regexp'
        },
        {
            string           => 'test',
            include_regexp   => '^t.*t$',
            exclude_regexp   => '^t.*t$',
            expected_boolean => 1,
            msg              => 'Test string with both include and exclude regexp matching the string'
        }
    );
    for my $test (@tests) {
        my $is_excluded = centreon::plugins::misc::is_excluded($test->{string}, $test->{include_regexp}, $test->{exclude_regexp});
        is($is_excluded, $test->{expected_boolean}, $test->{msg});
    }

    for my $test (@tests) {
        my $include = [ 'none', $test->{include_regexp} ];
        my $exclude = [ 'none', $test->{exclude_regexp} ];
        my $msg = "(Again with arrays) ".$test->{msg};
        my $is_excluded = centreon::plugins::misc::is_excluded($test->{string}, $include,  $exclude);
        is($is_excluded, $test->{expected_boolean}, $msg);
    }

}

test();
done_testing();

