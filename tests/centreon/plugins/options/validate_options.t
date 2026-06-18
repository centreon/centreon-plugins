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
# not_empty
# --------------------------------------------------------------------------
subtest 'not_empty' => sub {
    my @cases = (
        # nominal
        { value => 'something', expect => 1, msg => '"something" is not empty' },
        { value => '0',         expect => 1, msg => '"0" is not empty (numeric zero is valid)' },
        { value => ' ',         expect => 1, msg => 'space character is not empty' },
        # edge: empty and undef
        { value => '',          expect => 0, msg => 'empty string is empty' },
        { value => undef,       expect => 0, msg => 'undef value is empty' },
    );
    for my $case (@cases) {
        is($pv->($case->{value}, 'not_empty', 1), $case->{expect}, $case->{msg});
    }
};

# --------------------------------------------------------------------------
# numeric
# --------------------------------------------------------------------------
subtest 'numeric' => sub {
    my @cases = (
        # nominal
        { value => '0',   expect => 1, msg => '"0" is numeric' },
        { value => '123', expect => 1, msg => '"123" is numeric' },
        { value => '999', expect => 1, msg => '"999" is numeric' },
        # edge: non-numeric
        { value => '-1',   expect => 0, msg => '"-1" is not numeric (contains minus sign)' },
        { value => '12.3', expect => 0, msg => '"12.3" is not numeric (contains decimal point)' },
        { value => '',     expect => 1, msg => 'empty string skips validation' },
        { value => 'abc',  expect => 0, msg => '"abc" is not numeric' },
        { value => '3abc', expect => 0, msg => '"3abc" is not numeric (mixed alphanumeric)' },
        { value => 'a1b2', expect => 0, msg => '"a1b2" is not numeric' },
        { value => undef,  expect => 1, msg => 'undef skips validation' },
    );
    for my $case (@cases) {
        is($pv->($case->{value}, 'numeric', 1), $case->{expect}, $case->{msg});
    }
};

# --------------------------------------------------------------------------
# port
# --------------------------------------------------------------------------
subtest 'port' => sub {
    my @cases = (
        # nominal
        { value => '1',     expect => 1, msg => 'port 1 is valid (minimum)' },
        { value => '80',    expect => 1, msg => 'port 80 is valid (http)' },
        { value => '443',   expect => 1, msg => 'port 443 is valid (https)' },
        { value => '8080',  expect => 1, msg => 'port 8080 is valid' },
        { value => '65535', expect => 1, msg => 'port 65535 is valid (maximum)' },
        # edge: out of range
        { value => '0',     expect => 0, msg => 'port 0 is invalid (below minimum)' },
        { value => '65536', expect => 0, msg => 'port 65536 is invalid (above maximum)' },
        { value => '-1',    expect => 0, msg => 'port -1 is invalid (negative)' },
        { value => '99999', expect => 0, msg => 'port 99999 is invalid (out of range)' },
        # edge: non-numeric
        { value => 'abc',   expect => 0, msg => 'port "abc" is invalid (non-numeric)' },
        { value => '8080a', expect => 0, msg => 'port "8080a" is invalid (mixed alphanumeric)' },
        { value => '80.5',  expect => 0, msg => 'port "80.5" is invalid (decimal)' },
        { value => '',      expect => 1, msg => 'empty string skips validation' },
        { value => undef,   expect => 1, msg => 'undef skips validation' },
    );
    for my $case (@cases) {
        is($pv->($case->{value}, 'port', 1), $case->{expect}, $case->{msg});
    }
};

# --------------------------------------------------------------------------
# protocol_http
# --------------------------------------------------------------------------
subtest 'protocol_http' => sub {
    my @cases = (
        # nominal
        { value => 'http',  expect => 1, msg => '"http" is valid' },
        { value => 'https', expect => 1, msg => '"https" is valid' },
        # edge: case sensitivity
        { value => 'HTTP',  expect => 0, msg => '"HTTP" (uppercase) is invalid' },
        { value => 'HTTPS', expect => 0, msg => '"HTTPS" (uppercase) is invalid' },
        { value => 'Http',  expect => 0, msg => '"Http" (mixed case) is invalid' },
        # edge: invalid values
        { value => 'ftp',   expect => 0, msg => '"ftp" is invalid' },
        { value => 'ws',    expect => 0, msg => '"ws" is invalid' },
        { value => 'http:', expect => 0, msg => '"http:" is invalid (extra char)' },
        { value => 'http ', expect => 0, msg => '"http " (trailing space) is invalid' },
        { value => '',      expect => 1, msg => 'empty string skips validation' },
        { value => undef,   expect => 1, msg => 'undef skips validation' },
    );
    for my $case (@cases) {
        is($pv->($case->{value}, 'protocol_http', 1), $case->{expect}, $case->{msg});
    }
};

# --------------------------------------------------------------------------
# is_in
# --------------------------------------------------------------------------
subtest 'is_in' => sub {
    my @cases = (
        # nominal
        { value => 'red',    ref => ['red', 'green', 'blue'], expect => 1, msg => '"red" in [red, green, blue]' },
        { value => 'green',  ref => ['red', 'green', 'blue'], expect => 1, msg => '"green" in [red, green, blue]' },
        { value => 'blue',   ref => ['red', 'green', 'blue'], expect => 1, msg => '"blue" in [red, green, blue]' },
        # edge: not in list
        { value => 'yellow', ref => ['red', 'green', 'blue'], expect => 0, msg => '"yellow" not in [red, green, blue]' },
        { value => 'RED',    ref => ['red', 'green', 'blue'], expect => 0, msg => '"RED" (uppercase) not in list' },
        # edge: numeric values in list
        { value => '1',      ref => ['1', '2', '3'],          expect => 1, msg => '"1" in ["1", "2", "3"]' },
        { value => '5',      ref => ['1', '2', '3'],          expect => 0, msg => '"5" not in ["1", "2", "3"]' },
        { value => 1,        ref => ['1', '2', '3'],          expect => 1, msg => 'numeric 1 matches string "1" via eq' },
        # edge: empty list
        { value => 'red',    ref => [],                       expect => 0, msg => '"red" not in empty list' },
        # edge: empty string and undef
        { value => '',       ref => ['', 'a', 'b'],           expect => 1, msg => 'empty string in list' },
        { value => undef,    ref => ['a', 'b'],               expect => 1, msg => 'undef skips validation' },
    );
    for my $case (@cases) {
        is($pv->($case->{value}, 'is_in', $case->{ref}), $case->{expect}, $case->{msg});
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
