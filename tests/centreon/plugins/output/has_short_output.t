use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use centreon::plugins::options;
use centreon::plugins::output;

# has_short_output() tells whether at least one short message has been added,
# whatever its severity. The counter template relies on it to detect a mode that
# displayed nothing at all.

sub new_output {
    my $options = centreon::plugins::options->new();
    my $output  = centreon::plugins::output->new(options => $options);
    $options->set_output(output => $output);

    return $output;
}

subtest 'a fresh output holds no short message' => sub {
    my $output = new_output();

    is($output->has_short_output(), 0, 'nothing added yet');
};

subtest 'a short message of any severity is detected' => sub {
    for my $severity (qw/ok warning critical unknown OK WARNING CRITICAL UNKNOWN/) {
        my $output = new_output();
        $output->output_add(severity => $severity, short_msg => 'something');
        is($output->has_short_output(), 1, "severity '$severity' counts");
    }
};

subtest 'the default severity (OK) is detected too' => sub {
    my $output = new_output();
    $output->output_add(short_msg => 'implicitly ok');

    is($output->has_short_output(), 1, 'output_add without severity counts');
};

subtest 'a long message alone is not a short output' => sub {
    my $output = new_output();
    $output->output_add(long_msg => 'detail only');

    is($output->has_short_output(), 0, 'long_msg does not count');
};

subtest 'an empty string is still a short message' => sub {
    my $output = new_output();
    $output->output_add(severity => 'ok', short_msg => '');

    is($output->has_short_output(), 1, 'an empty short_msg was still added');
};

subtest 'several messages keep the flag set' => sub {
    my $output = new_output();
    $output->output_add(severity => 'ok', short_msg => 'first');
    $output->output_add(severity => 'critical', short_msg => 'second');

    is($output->has_short_output(), 1, 'still detected with mixed severities');
};

done_testing();
