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
    {'logger' => undef,             'config_file' => undef,                 'test' => '$error_message =~ /FATAL: No logger given to the constructor/'},
    {'logger' => $global_logger,    'config_file' => undef,                 'test' => '$vault->{enabled} == 0'},
    {'logger' => $global_logger,    'config_file' => 'does_not_exist.json',  'test' => '$vault->{enabled} == 0'}
);

for my $i (0..$#test_data) {
    my $logger         = $test_data[$i]->{logger};
    my $config_file    = $test_data[$i]->{config_file};
    my $test           = $test_data[$i]->{test};

    use Data::Dumper;
    #print("Test $i with logger " . Dumper($logger) ."\n");
    eval {
        $vault = centreon::script::centreonvault->new(
            (
                'logger' => $logger,
                'config_file' => $config_file
            )
        );
    };

    my $error_message = defined($@) ? $@ : '';
    print("Test $i with vault " . Dumper($vault) ."\n");

    ok (eval($test), "TEST CASE $i FAILED: '$test' with error message: '" . $error_message . "'" );
}

done_testing();

