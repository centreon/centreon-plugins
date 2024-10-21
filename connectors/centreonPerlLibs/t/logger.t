#!/usr/bin/perl
use strict;
use warnings;

use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../src";
use centreon::common::logger;

# Each function test a different aspect of the library (roughtly one public function each).
# To be sure there is no side effect each test create it's own test object
sub test_severity {
    my $logger = centreon::common::logger->new();
    is($logger->severity(), "warning", "default severity should be warning.");

    for my $sev ('fatal', 'error', 'warning', 'notice', 'info', 'debug') {
        $logger->severity($sev);
        is($logger->severity(), $sev, "severity $sev was correctly set.");
    }
}
# By default the logger should write to stdout, so we capture stdout to a variable and check what the object have written.
sub test_writeLogInfo {
    my $logger = centreon::common::logger->new();
    $logger->flush_output(enabled => 1);
    $logger->severity("debug");
    my $out;
    my $logExemple = "this is an info log.";
    do {
        local *STDOUT;
        open STDOUT, ">", \$out;
        $logger->writeLogInfo($logExemple);
    };
    my $log = check_log_format_with_date_no_pid($out, "info");

    is($log, $logExemple, "log is the same as what we sent.");

    print "written to original STDOUT : $out\n";
}

sub main {
    test_severity();
    test_writeLogInfo();
    #test_file_mode();
    #test_is_file_mode();


    done_testing;
}
# Helper function
sub check_log_format_with_date_no_pid {
    # the best way to check the date would be to mock the time() function, and to run get_date().
    # as it is a builtin function, it is possible but hard to setup and prone various side effect.
    my $log = shift;
    my $severity = shift;
    ok(($log =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[$severity\] (.*$)/), "log format is respected.");
    ok((defined $1), "the log is not empty");
    return $1;
}

&main;