#!/usr/bin/perl
use strict;
use warnings;
use Test2::V0;
use Test2::Plugin::NoWarnings echo => 1;

BEGIN {
    use FindBin;
    use lib "$FindBin::RealBin/../../../src";
}

BEGIN {
    # Test with modules that do not exist ExIsTe::PaS and ExIsTe::pAs
    # Program should not die and just log an error message
    eval q{
        local *STDOUT;  # to catch error message
        open STDOUT, '>', '/dev/null';
        use lib "$FindBin::RealBin/../../../src";
        use centreon::script::centreon_vmware_requirements;
        my $module = centreon::script::centreon_vmware_requirements->new();
        $module->{required} = [ 'ExIsTe::PaS', 'ExIsTe::pAs' ];
        $module->run();
    };
    my $test = $@ // '';
    ok($test =~ /To make the Centreon VMware VM Monitoring Connector work, you will need the Perl VMware SDK/m, "Test for missing modules");
}

BEGIN {
    # Test with existing modules Data::Dumper and FindBin
    # Program should not die and produce no output
    eval q{
        use lib "$FindBin::RealBin/../../../src";
        use centreon::script::centreon_vmware_requirements;
        my $module = centreon::script::centreon_vmware_requirements->new();
        $module->{required} = [ 'Data::Dumper', 'FindBin' ];
        $module->run();
    };
    my $test = $@ // '';
    ok($test eq '', "Test for installed modules");
}

done_testing();
