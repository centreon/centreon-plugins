
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is like match};
use FindBin;
use lib "$FindBin::RealBin/../../../src";
use centreon::plugins::misc;
use centreon::plugins::output;
use centreon::plugins::options;
# in real world one should use execute(), but as many options are not supported by windows_execute,
# the signature is not coherent, and we want to test everything on this unix_execute()
sub test_unix_execute {
    my $mock_output = mock 'centreon::plugins::output'; # this is from Test2::Tools::Mock, included by Test2::V0

    my $option = centreon::plugins::options->new();
    my $output = centreon::plugins::output->new(options => $option);
    my ($stdout, $exit_code) = centreon::plugins::misc::unix_execute(
        output  => $output,
        options => { timeout => 10 },
        command => 'echo stringToOutput $(echo adding)',
    );
    is($stdout, "stringToOutput adding", 'bash $() are interpreted');

    ($stdout, $exit_code) = centreon::plugins::misc::unix_execute(
        output                  => $output,
        options                 => { timeout => 10 },
        command                 => 'echo',
        command_options         => 'string to output $( echo noworking)',
        no_shell_interpretation => 1,
    );
    is($stdout, 'string to output $( echo noworking)', 'no interpretation with args and no_shell_interpretation');
}

test_unix_execute();
done_testing();
