use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use centreon::plugins::options;

# Direct reference to the internal (non-exported) function
my $pv = \&centreon::plugins::options::perform_validation;

# --------------------------------------------------------------------------
# Undefined arguments: any undef param skips the check → always valid
# --------------------------------------------------------------------------
subtest 'undef arguments always pass' => sub {
    is($pv->(undef, 'greater_than',  5),    1, 'undef value');
    is($pv->(5,     undef,           5),    1, 'undef operation');
    is($pv->(5,     'greater_than',  undef), 1, 'undef reference');
    is($pv->(undef, undef,           undef), 1, 'all three undef');
};

# --------------------------------------------------------------------------
# greater_than
# --------------------------------------------------------------------------
subtest 'greater_than' => sub {
    my @cases = (
        # nominal
        { value => 10,    ref => 5,  expect => 1, msg => '10 > 5  (value above threshold)' },
        { value => 3,     ref => 5,  expect => 0, msg => '3 not > 5  (value too small)' },
        { value => 5,     ref => 5,  expect => 0, msg => '5 not > 5  (equal is not strictly greater)' },
        # decimals and negatives
        { value => 5.5,   ref => 5,  expect => 1, msg => '5.5 > 5  (decimal above threshold)' },
        { value => 4.9,   ref => 5,  expect => 0, msg => '4.9 not > 5  (decimal below threshold)' },
        { value => -1,    ref => 0,  expect => 0, msg => '-1 not > 0  (negative value)' },
        { value => 0,     ref => -5, expect => 1, msg => '0 > -5  (zero against negative reference)' },
        # edge: non-numeric values
        { value => '',    ref => 5,  expect => 1, msg => 'empty string not > 5  (non-numeric)' },
        { value => 'abc', ref => 5,  expect => 0, msg => '"abc" not > 5  (non-numeric string)' },
        { value => '3abc',ref => 2,  expect => 0, msg => '"3abc" not > 2  (not purely numeric)' },
    );
    for my $case (@cases) {
        is($pv->($case->{value}, 'greater_than', $case->{ref}), $case->{expect}, $case->{msg});
    }
};

# --------------------------------------------------------------------------
# greater_than_or_equal
# --------------------------------------------------------------------------
subtest 'greater_than_or_equal' => sub {
    my @cases = (
        # nominal
        { value => 10, ref => 5,  expect => 1, msg => '10 >= 5  (value above threshold)' },
        { value => 5,  ref => 5,  expect => 1, msg => '5 >= 5   (equal is valid)' },
        { value => 3,  ref => 5,  expect => 0, msg => '3 not >= 5  (value too small)' },
        # decimals
        { value => 5.0, ref => 5, expect => 1, msg => '5.0 >= 5  (decimal equal)' },
        { value => 4.9, ref => 5, expect => 0, msg => '4.9 not >= 5  (just below threshold)' },
        # edge: non-numeric values
        { value => '',    ref => 5, expect => 1, msg => 'empty string not >= 5  (non-numeric)' },
        { value => 'abc', ref => 5, expect => 0, msg => '"abc" not >= 5  (non-numeric string)' },
    );
    for my $case (@cases) {
        is($pv->($case->{value}, 'greater_than_or_equal', $case->{ref}), $case->{expect}, $case->{msg});
    }
};

# --------------------------------------------------------------------------
# less_than
# --------------------------------------------------------------------------
subtest 'less_than' => sub {
    my @cases = (
        # nominal
        { value => 3,  ref => 5, expect => 1, msg => '3 < 5  (value below threshold)' },
        { value => 5,  ref => 5, expect => 0, msg => '5 not < 5  (equal is not strictly less)' },
        { value => 10, ref => 5, expect => 0, msg => '10 not < 5  (value too large)' },
        # decimals and negatives
        { value => 4.9, ref => 5,  expect => 1, msg => '4.9 < 5  (decimal below threshold)' },
        { value => 5.1, ref => 5,  expect => 0, msg => '5.1 not < 5  (decimal above threshold)' },
        { value => -1,  ref => 0,  expect => 1, msg => '-1 < 0  (negative below zero)' },
        # edge: non-numeric values
        { value => '',    ref => 5, expect => 1, msg => 'empty string: non-numeric value rejected' },
        { value => 'abc', ref => 5, expect => 0, msg => '"abc": non-numeric string rejected' },
    );
    for my $case (@cases) {
        is($pv->($case->{value}, 'less_than', $case->{ref}), $case->{expect}, $case->{msg});
    }
};

# --------------------------------------------------------------------------
# less_than_or_equal
# --------------------------------------------------------------------------
subtest 'less_than_or_equal' => sub {
    my @cases = (
        # nominal
        { value => 3,  ref => 5, expect => 1, msg => '3 <= 5  (value below threshold)' },
        { value => 5,  ref => 5, expect => 1, msg => '5 <= 5  (equal is valid)' },
        { value => 10, ref => 5, expect => 0, msg => '10 not <= 5  (value too large)' },
        # decimals
        { value => 5.0, ref => 5, expect => 1, msg => '5.0 <= 5  (decimal equal)' },
        { value => 5.1, ref => 5, expect => 0, msg => '5.1 not <= 5  (just above threshold)' },
        # edge: non-numeric values
        { value => '',    ref => 5, expect => 1, msg => 'empty string: non-numeric value rejected' },
        { value => 'abc', ref => 5, expect => 0, msg => '"abc": non-numeric string rejected' },
        { value => '7abc',ref => 5, expect => 0, msg => '"7abc": not purely numeric, rejected' },
    );
    for my $case (@cases) {
        is($pv->($case->{value}, 'less_than_or_equal', $case->{ref}), $case->{expect}, $case->{msg});
    }
};

# --------------------------------------------------------------------------
# regexp_match
# --------------------------------------------------------------------------
subtest 'regexp_match' => sub {
    my @cases = (
        # nominal
        { value => 'hello',       ref => 'hello',    expect => 1, msg => 'exact match' },
        { value => 'world',       ref => 'hello',    expect => 0, msg => 'no match' },
        { value => 'hello world', ref => 'hello',    expect => 1, msg => 'partial match' },
        { value => 'hello',       ref => '^hello$',  expect => 1, msg => 'anchored match' },
        { value => 'hello world', ref => '^hello$',  expect => 0, msg => 'anchored: trailing chars cause mismatch' },
        # numeric strings
        { value => '42',          ref => '^[0-9]+$', expect => 1, msg => 'numeric string matches digit pattern' },
        { value => 'abc',         ref => '^[0-9]+$', expect => 0, msg => 'alpha string does not match digit pattern' },
        # edge: empty string
        { value => '',            ref => '.*',       expect => 1, msg => 'empty string matches .*' },
        { value => '',            ref => '.+',       expect => 1, msg => 'empty string does not match .+' },
        { value => '',            ref => '^$',       expect => 1, msg => 'empty string matches ^$' },
    );
    for my $case (@cases) {
        is($pv->($case->{value}, 'regexp_match', $case->{ref}), $case->{expect}, $case->{msg});
    }
};

# --------------------------------------------------------------------------
# validate_options: integration via the options object
# --------------------------------------------------------------------------
subtest 'validate_options: valid value does not call option_exit' => sub {
    my $exit_called = 0;
    my $mock_output = mock {} => (
        add => [
            option_exit => sub { $exit_called = 1; die "option_exit\n" }
        ]
    );

    my $opts = centreon::plugins::options->new();
    $opts->{output}         = $mock_output;
    $opts->{validation}     = { level => { greater_than => 5 } };
    $opts->{options_stored} = { level => 10 };

    eval { $opts->validate_options() };
    is($exit_called, 0, 'value 10 satisfies greater_than 5, no option_exit');
};

subtest 'validate_options: violated constraint calls option_exit' => sub {
    my $exit_called = 0;
    my $exit_msg    = '';
    my $mock_output = mock {} => (
        add => [
            option_exit => sub {
                my ($self, %opts) = @_;
                $exit_called = 1;
                $exit_msg    = $opts{short_msg} // '';
                die "option_exit\n";
            }
        ]
    );

    my $opts = centreon::plugins::options->new();
    $opts->{output}         = $mock_output;
    $opts->{validation}     = { level => { greater_than => 5 } };
    $opts->{options_stored} = { level => 3 };

    eval { $opts->validate_options() };
    is($exit_called, 1, 'value 3 violates greater_than 5, option_exit called');
    like($exit_msg, qr/level/, 'error message mentions the option name');
};

subtest 'validate_options: undef value skips validation' => sub {
    my $exit_called = 0;
    my $mock_output = mock {} => (
        add => [
            option_exit => sub { $exit_called = 1; die "option_exit\n" }
        ]
    );

    my $opts = centreon::plugins::options->new();
    $opts->{output}         = $mock_output;
    $opts->{validation}     = { level => { greater_than => 5 } };
    $opts->{options_stored} = { level => undef };

    eval { $opts->validate_options() };
    is($exit_called, 0, 'undef value bypasses validation, no option_exit');
};

subtest 'validate_options: multiple constraints, first violation stops check' => sub {
    my $exit_count = 0;
    my $mock_output = mock {} => (
        add => [
            option_exit => sub { $exit_count++; die "option_exit\n" }
        ]
    );

    my $opts = centreon::plugins::options->new();
    $opts->{output} = $mock_output;
    $opts->{validation} = {
        count   => { greater_than => 0, less_than => 100 },
        timeout => { greater_than_or_equal => 1 },
    };
    $opts->{options_stored} = { count => 50, timeout => 10 };

    eval { $opts->validate_options() };
    is($exit_count, 0, 'all constraints satisfied, no option_exit');
};

done_testing();
