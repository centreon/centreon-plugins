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

    my @tests = (
        {
            expect => '"string to" output "$( echo noworking)"',
            msg    => 'double quote stay when no interpretation',
            args   => {
                command_path            => "/bin",
                command                 => 'echo',
                command_options         => '"string to" output "$( echo noworking)"',
                no_shell_interpretation => 1,
            }
        },
        {
            expect => 'string to output noworking',
            msg    => 'double quote diseapear when interpretation is enabled',
            args   => {
                command_path    => "/bin",
                command         => 'echo',
                command_options => '"string to" output "$( echo noworking)"',
            }
        },
        {
            expect => 'stringToOutput adding',
            msg    => 'interpretation by default active',
            args   => {
                command => 'echo stringToOutput $(echo adding)',
            }
        },
        {
            expect => 'stringToOutput $(echo adding)',
            msg    => 'interpretation by default active',
            args   => {
                command                 => 'echo stringToOutput $(echo adding)',
                no_shell_interpretation => 1,
            }
        },
        {
            expect => '',
            msg    => "no error when no argument given to command without interpolation",
            args   => {
                command                 => 'echo',
                no_shell_interpretation => 1,
            }
        }

    );
    for my $test (@tests) {
        my ($stdout, $exit_code) = centreon::plugins::misc::unix_execute(
            output  => $output,
            options => { timeout => 10 },
                    no_quit                 => 1,
            %{$test->{args}},
        );
        is($stdout, $test->{expect}, $test->{msg});
    }

    my ($stdout, $exit_code) = centreon::plugins::misc::unix_execute(
        output                  => $output,
        options                 => { timeout => 10 },
        command                 => 'NoBinary',
        command_output          => '"string to" output "$( echo noworking)"',
        no_shell_interpretation => 1,
        no_quit                 => 1
    );
    like($stdout, qr/Can't exec "NoBinary": No such file or directory at.*/, 'no_quit option always return');
    ($stdout, $exit_code) = centreon::plugins::misc::unix_execute(
        output                  => $output,
        options                 => { timeout => 10 },
        sudo                    => 1,
        command                 => 'NoBinary',
        command_output          => '"string to" output "$( echo noworking)"',
        no_shell_interpretation => 1,
        no_quit                 => 1
    );
    like($stdout, qr/Can't exec "sudo": No such file or directory at.*/, 'sudo option add sudo binary before command');

}

test_unix_execute();
done_testing();
