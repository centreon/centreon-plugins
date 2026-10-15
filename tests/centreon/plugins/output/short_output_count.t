use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use centreon::plugins::options;
use centreon::plugins::output;

# short_output_count() returns how many short messages have been added, whatever their
# severity. The counter template compares it with the number of 'message_multiple' claims
# it emitted itself, to detect a mode that reported nothing of its own.

sub new_output {
    my $options = centreon::plugins::options->new();
    my $output  = centreon::plugins::output->new(options => $options);
    $options->set_output(output => $output);

    return $output;
}

subtest 'a fresh output holds no short message' => sub {
    my $output = new_output();

    is($output->short_output_count(), 0, 'nothing added yet');
};

subtest 'a short message of any severity is counted' => sub {
    for my $severity (qw/ok warning critical unknown OK WARNING CRITICAL UNKNOWN/) {
        my $output = new_output();
        $output->output_add(severity => $severity, short_msg => 'something');
        is($output->short_output_count(), 1, "severity '$severity' counts");
    }
};

subtest 'the default severity (OK) is counted too' => sub {
    my $output = new_output();
    $output->output_add(short_msg => 'implicitly ok');

    is($output->short_output_count(), 1, 'output_add without severity counts');
};

subtest 'an option error is counted' => sub {
    my $output = new_output();
    $output->add_option_msg(short_msg => 'bad option');

    is($output->short_output_count(), 1, 'the UNQUALIFIED_YET severity counts');
};

subtest 'a long message alone is not counted' => sub {
    my $output = new_output();
    $output->output_add(long_msg => 'detail only');

    is($output->short_output_count(), 0, 'long_msg does not count');
};

subtest 'an empty string is still a short message' => sub {
    my $output = new_output();
    $output->output_add(severity => 'ok', short_msg => '');

    is($output->short_output_count(), 1, 'an empty short_msg was still added');
};

subtest 'messages accumulate, including within one severity' => sub {
    my $output = new_output();
    $output->output_add(severity => 'ok', short_msg => 'first');
    $output->output_add(severity => 'ok', short_msg => 'second');
    $output->output_add(severity => 'critical', short_msg => 'third');

    is($output->short_output_count(), 3, 'three messages over two severities');
};

done_testing();
