use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is like match};
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use centreon::plugins::misc qw/exprintf/;

sub test {

    my @tests = (
        {
            template         => 'Hello %{name}',
            datas            => { name => 'World' },
            default          => '',
            expected_result  => 'Hello World',
            msg              => 'Test simple variable substitution'
        },
        {
            template         => 'Name: %{name}, Age: %{age}',
            datas            => { name => 'John', age => 30 },
            default          => '',
            expected_result  => 'Name: John, Age: 30',
            msg              => 'Test multiple variable substitution'
        },
        {
            template         => 'Name: %{name}, Age: %{age}',
            datas            => { name => 'John' },
            default          => 'N/A',
            expected_result  => 'Name: John, Age: N/A',
            msg              => 'Test missing variable with default value'
        },
        {
            template         => 'Name: %{name}, Age: %{age}',
            datas            => { name => 'John' },
            default          => '',
            expected_result  => 'Name: John, Age: ',
            msg              => 'Test missing variable with empty default'
        },
        {
            template         => 'Value: %{bytes}',
            datas            => { bytes => 1024 },
            default          => '',
            expected_result  => 'Value: 1024',
            msg              => 'Test variable without filter'
        },
        {
            template         => 'No variables here',
            datas            => { name => 'John' },
            default          => '',
            expected_result  => 'No variables here',
            msg              => 'Test template with no variables'
        },
        {
            template         => 'Name: %{name}',
            datas            => undef,
            default          => '',
            expected_result  => 'Name: %{name}',
            msg              => 'Test non-hash datas returns template unchanged'
        },
        {
            template         => 'Multiple: %{a} and %{a}',
            datas            => { a => 'test' },
            default          => '',
            expected_result  => 'Multiple: test and test',
            msg              => 'Test multiple occurrences of same variable'
        },
        {
            template         => 'Value: %{value}',
            datas            => { value => 0 },
            default          => 'default',
            expected_result  => 'Value: 0',
            msg              => 'Test that 0 is not replaced with default'
        },
        {
            template         => 'Value: %{value}',
            datas            => { value => '' },
            default          => 'default',
            expected_result  => 'Value: ',
            msg              => 'Test that empty string is not replaced with default'
        },
        {
            template         => 'Text: %{text}',
            datas            => 'not a hash',
            default          => '',
            expected_result  => 'Text: %{text}',
            msg              => 'Test non-hash scalar datas returns template unchanged'
        },
        {
            template         => 'Item: %{item}',
            datas            => [],
            default          => '',
            expected_result  => 'Item: %{item}',
            msg              => 'Test array datas returns template unchanged'
        },
        {
            template         => 'Bytes (storage): %{bytes|storage}',
            datas            => { bytes => 1024 },
            default          => '',
            expected_result  => 'Bytes (storage): 1.00KB',
            msg              => 'Test storage filter (binary 1024)'
        },
        {
            template         => 'Bytes (network): %{bytes|network}',
            datas            => { bytes => 1000 },
            default          => '',
            expected_result  => 'Bytes (network): 1.00Kb',
            msg              => 'Test network filter (decimal 1000)'
        },
        {
            template         => 'Large storage: %{bytes|storage}',
            datas            => { bytes => 1048576 },
            default          => '',
            expected_result  => 'Large storage: 1.00MB',
            msg              => 'Test storage filter with larger value'
        },
        {
            template         => 'Multiple filters: %{a|storage} and %{b|network}',
            datas            => { a => 1024, b => 1000 },
            default          => '',
            expected_result  => 'Multiple filters: 1.00KB and 1.00Kb',
            msg              => 'Test multiple different filters'
        },
        {
            template         => 'Unknown filter: %{value|unknown}',
            datas            => { value => 100 },
            default          => '',
            expected_result  => 'Unknown filter: 100',
            msg              => 'Test unknown filter (no transformation)'
        },
        {
            template         => 'Sprintf format percent: %{value|%.2f}%',
            datas            => { value => 32.12 },
            default          => '',
            expected_result  => 'Sprintf format percent: 32.12%',
            msg              => 'Test unknown filter (no transformation)'
        },
        {
            template         => 'Sprintf format custom: %{value|%.5f}',
            datas            => { value => 32.123456789 },
            default          => '',
            expected_result  => 'Sprintf format custom: 32.12346',
            msg              => 'Test unknown filter (no transformation)'
        },
        {
            template         => 'Perl array: %{value|array}',
            datas            => { value => [ 'VAL1', 'VAL2' ] },
            default          => '',
            expected_result  => 'Perl array: VAL1, VAL2',
            msg              => 'Test perl array'
        },
        {
            template         => 'Undefined Perl array: %{value|array}',
            datas            => { value => undef },
            default          => undef,
            expected_result  => 'Undefined Perl array: ',
            msg              => 'Test undefined perl array'
        },
        {
            template         => 'Undefined Perl array with default: %{value|array}',
            datas            => { value => undef },
            default          => [ 'DEF1', 'DEF2' ],
            expected_result  => 'Undefined Perl array with default: DEF1, DEF2',
            msg              => 'Test undefined perl array with default'
        }
    );

    for my $test (@tests) {
        my $result = exprintf($test->{template}, $test->{datas}, $test->{default});
        is($result, $test->{expected_result}, $test->{msg});
    }

}

test();
done_testing();
