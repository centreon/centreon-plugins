#!/usr/bin/perl
use strict;
use warnings;
use Test2::V0;
use Test2::Plugin::NoWarnings echo => 1;

use FindBin;
use lib "$FindBin::RealBin/../../../src";
use centreon::plugins::perfdata;

my $perfdata = centreon::plugins::perfdata->new();

###############################################################################
# Testing trim()                                                              #
###############################################################################

is($perfdata->trim(' toto '),       'toto');
is($perfdata->trim(' toto'),        'toto');
is($perfdata->trim('toto '),        'toto');
is($perfdata->trim('toto'),         'toto');
is($perfdata->trim(' toto '),       'toto');
is($perfdata->trim(' toto titi '),  'toto titi');
is($perfdata->trim(' toto titi'),   'toto titi');
is($perfdata->trim('toto titi '),   'toto titi');
is($perfdata->trim('toto titi'),    'toto titi');
is($perfdata->trim(' '),            '');
is($perfdata->trim('      '),       '');
is($perfdata->trim(''),             '');

is($perfdata->trim("\ttoto\t"),         "toto");
is($perfdata->trim("\t toto"),          "toto");
is($perfdata->trim("toto\t "),          "toto");
is($perfdata->trim("toto"),             "toto");
is($perfdata->trim(" \ttoto \t"),       "toto");
is($perfdata->trim("\t toto titi\t "),  "toto titi");
is($perfdata->trim(" \ttoto titi"),     "toto titi");
is($perfdata->trim("toto\ttiti\t"),     "toto\ttiti");
is($perfdata->trim("toto\ttiti"),       "toto\ttiti");
is($perfdata->trim("\t"),               "");
is($perfdata->trim("\t\t\t\t\t"),       "");
is($perfdata->trim(""),                 "");

###############################################################################
# Testing change_bytes()                                                              #
###############################################################################

#is(join('', $perfdata->change_bytes(value => 1024)), '1.00KiB');
#is(join('', $perfdata->change_bytes(value => 1024, network => 1)), '1.02Kb');

done_testing();

