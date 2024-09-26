#!/usr/bin/perl
use strict;
use warnings;
use Test2::V0;
use Test2::Plugin::NoWarnings echo => 1;

use FindBin;
use lib qw($FindBin::RealBin/../../../src);

use centreon::script::centreonvault;
use centreon::vmware::logger;
my $vault;
my $global_logger = centreon::vmware::logger->new();
my @test_data = (
        {'logger' => undef,             'config_file' => undef,         'expected_error' => 'FATAL: No logger given to the constructor'}
);

for my $i (0..$#test_data) {
    my $logger         = $test_data[$i]->{logger};
    my $config_file    = $test_data[$i]->{config_file};
    my $expected_error = $test_data[$i]->{expected_error};

    use Data::Dumper;
    print("Test $i with logger " . Dumper($logger) ."\n");
    eval { $vault = centreon::script::centreonvault->new(('logger' => $logger, 'config_file' => $config_file)); };
    my $msg = $@;
    ok ($msg =~ /$expected_error/, "test $i compared $msg to $expected_error");
}


done_testing();

