use strict;
use warnings;

package MockOptions;
sub new { bless { extra_arguments => [ ], option_results => {}, default => {}, custom => {} }, shift }
sub add_options { }
sub add_help { }

package MockOutput;
sub new { bless {}, shift }
sub add_option_msg { }
sub output_add { }
sub use_new_perfdata { }
sub option_exit { }

package main;

# Unit tests to check that the plugin constructs a valid redis-cli command with the corresponding parameters

use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../src";
use database::redis::mode::commands;
use database::redis::custom::cli;

my $capture;
my $options = MockOptions->new();
my $output  = MockOutput->new();

my $plugin_misc = mock 'centreon::plugins::misc';

$plugin_misc->override('execute' => sub {
    my (%options) = @_;
    $capture = "$options{command} $options{command_options}";
});

my $plugin = database::redis::mode::commands->new(
    options => $options,
    output => $output,
    mode => 'commands',
);
$plugin->init(%$options);

my $cust = database::redis::custom::cli->new(
    options => $options,
    output => $output,
);
$options->{custom} = $cust;

foreach my $test ({ title => 'Test --key parameter',    param => { key => 'private.key'},       expect => q(--key 'private.key') },
                  { title => 'Test --cert parameter',   param => { cert => 'dummy.crt'},        expect => q(--cert 'dummy.crt') },
                  { title => 'Test --cacert parameter', param => { cacert => 'ca.crt'},         expect => q(--cacert 'ca.crt') },) {
    $cust->set_options(option_results => $test->{param} );
    $cust->check_options();

    $plugin->manage_selection(%$options);

    ok($capture =~ /$test->{expect}/, "$test->{title}");
}

done_testing;
