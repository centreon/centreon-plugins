use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../../../src";
use storage::ibm::storwize::ssh::custom::api;

my $_test_file = '/tmp/test_storwize_api_c_'.$$;
my $_banner_file = '/tmp/test_storwize_api_b_'.$$;

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
    sub add_option_msg { warn "err==".$_[1]->{short_msg} }
    sub option_exit { die }
}

{
    package MockSSH;
    sub new { bless {}, shift }
    sub execute { my ($self, %options) = @_; join ('', `/bin/sh $_banner_file`).join ('', `$options{command}`) }
}

sub process_test {
    # Test object creation
    my $api;

    # Create mock object
    my $options = MockOptions->new();
    my $output  = MockOutput->new();

    eval {
        $api = storage::ibm::storwize::ssh::custom::api->new(
            options => $options,
            output => $output
        );
        $api->{ssh} = MockSSH->new();
    };
    ok(!$@, 'Object creation without errors');

    my %options = (
        hostname => 'localhost',
        timeout => 10,
        command => "/bin/sh $_test_file",
        command_path => '/bin',
        command_options => ''
    );
    $api->set_options(option_results => \%options);

    my $result;

    my $template = q~id:time:last_timestamp:severity:alert:object_id:event_id:description
101:250930142211:250930142211:warning:yes:0x1234:0x01A2:Fan speed exceeded threshold
102:250930150542:250930150542:critical:yes:0x1235:0x01B7:Power supply failure detected
104:251001104256:251001104256:critical:yes:0x1237:0x01D1:Temperature sensor reading critical
~;

    my @commands_output_expected = ( { title => 'command without banner',
                                       banner => '',
                                       expected => $template,
                                     },
                                     { title => 'command with banner',
                                       banner => "A BANNER LINE1\nA BANNER LINE2\nA BANNER LINE3\n",
                                       expected => $template
                                     },
                                     { title => 'command with banner and special characters part 1',
                                       banner => "A BANNER LINE1 COL1:COL2:COL3\nA BANNER LINE2 COL1;COL2;COL3\nA BANNER LINE3 COL1|COL2|COL3\n",
                                       expected => $template
                                     },
                                     { title => 'command with banner and special characters part 2',
                                       banner => 'A BANNER LINE1 $LINE1 @LINE1'."\n".'A BANNER LINE2 ^"$/\\'."\n".'A BANNER LINE3 "" "     % & !'."\n",
                                       expected => $template
                                     }

    );

    # This file will be used to mock the command output
    open(my $fic, '>', $_test_file) or die("Cannot create file $_test_file: $!");
    print $fic qq(#!/bin/sh\ncat<<EOF\n).
               $template.
               qq(EOF\n);
    close($fic);

    foreach my $test (@commands_output_expected) {
        # This file will be used to add a banner before the command output
        open(my $fic, '>', $_banner_file) or die("Cannot create file $_banner_file: $!");
        print $fic "#!/bin/sh\n";
        if ($test->{banner}) {
            print $fic qq(cat<<EOF\n).
                       $test->{banner}.
                       qq(EOF\n);
        }
        close($fic);

        # Test command execution
        $result = $api->execute_command(wrap_command => 1);

        ok($result eq $test->{expected}, $test->{title});
    }

    unlink($_banner_file);
    unlink($_test_file);
}

process_test;

done_testing();
