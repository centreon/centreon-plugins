use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../src";
use storage::ibm::storwize::ssh::custom::api;
use centreon::plugins::ssh;

# Test the sshcli SSH backend

my $_test_cmd = 'test_cmd_'.$$;
my $_fake_ssh = '/tmp/test_fake_ssh_'.$$;

# Mock options class
{
    package MockOptions;
    sub new { bless {}, shift }
    sub add_options { }
    sub add_help { }
}

{
    package MockOutput;
    sub new { bless {}, shift }
    sub add_option_msg { }
    sub option_exit { die }
}

sub process_test {
    # Create mock object
    my $options = MockOptions->new();
    my $output = MockOutput->new();

    my $ssh = centreon::plugins::ssh->new(options => $options, output => $output);
    $ssh->check_options(option_results => { ssh_backend => 'sshcli', opt_exit => 'ok', sshcli_command => $_fake_ssh });

    ok(!$@, 'Object creation without errors');

    my %options = (
        hostname => 'localhost',
        timeout => 10,
        command => "$_test_cmd",
        # In this test we include command_path and command_options usage
        command_path => '/tmp',
        command_options => 'PARA'
    );

    my $template = q~id:time:last_timestamp:severity:alert:object_id:event_id:description
101:250930142211:250930142211:warning:yes:0x1234:0x01A2:Fan speed exceeded threshold
102:250930150542:250930150542:critical:yes:0x1235:0x01B7:Power supply failure detected
104:251001104256:251001104256:critical:yes:0x1237:0x01D1:Temperature sensor reading critical~;

    my @commands_output_expected = ( { title => 'command without banner',
                                       banner => '',
                                       expected => $template,
                                     },
                                     { title => 'command with banner',
                                       banner => "A BANNER LINE1\nA BANNER LINE2\nA BANNER LINE3",
                                       expected => $template
                                     },
                                     { title => 'command with banner and special characters part 1',
                                       banner => "A BANNER LINE1 COL1:COL2:COL3\nA BANNER LINE2 COL1;COL2;COL3\nA BANNER LINE3 COL1|COL2|COL3",
                                       expected => $template
                                     },
                                     { title => 'command with banner and special characters part 2',
                                       banner => 'A BANNER LINE1 $LINE1 @LINE1'."\n".'A BANNER LINE2 ^"$/\\'."\n".'A BANNER LINE3 "" "     % & !',
                                       expected => $template
                                     }

    );

    # This file will be used to mock the command output
    open(my $fic, '>', "/tmp/$_test_cmd") or die("Cannot create file $_test_cmd: $!");
    print $fic qq(#!/bin/sh\ncat<<EOF\n).
               $template.
               qq(\nEOF\n).
               q(if [ "$1" != "PARA" ]; then echo "missing PARA"; fi);
    close($fic);
    chmod 0755, "/tmp/$_test_cmd" or die("Cannot chmod file /tmp/$_test_cmd: $!");

    foreach my $test (@commands_output_expected) {
        # This file will be used to add a banner before the command output
        open(my $fic, '>', $_fake_ssh) or die("Cannot create file $_fake_ssh: $!");
        print $fic "#!/bin/sh\n";
        print $fic q(skip_banner=`echo "$*" | grep -c -- "-o LogLevel=ERROR"`)."\n";
        print $fic q(if [ "$skip_banner" = "0" ]; then cat<<EOF).
                   "\n$test->{banner}\n".
                   qq(EOF\n).
                   qq(fi\n)
                        if $test->{banner} ne '';
        print $fic q(cmd=`echo "$*" | sed 's/.\+\/tmp\//\/tmp\//'`; if [ "$cmd" != "" ]; then eval "$cmd"; fi)."\n";
        close($fic);
        chmod 0755, $_fake_ssh or die("Cannot chmod file $_fake_ssh: $!");

        # Test command execution
        my ($result, $exit_code) = $ssh->execute(%options);

        ok($result eq $test->{expected}, $test->{title});
    }

    unlink($_test_cmd);
    unlink($_fake_ssh);
}

process_test;

done_testing();
