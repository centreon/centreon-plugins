use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use centreon::plugins::options;
use centreon::plugins::output;
use centreon::plugins::constants qw(:counters :values);

# --------------------------------------------------------------------------
# Fixture modes: one per counter layout we want to exercise.
# --------------------------------------------------------------------------

{
    # COUNTER_TYPE_INSTANCE with no instance at all
    package Test::Mode::EmptyInstance;
    use base qw(centreon::plugins::templates::counter);
    use centreon::plugins::constants qw(:counters);

    sub set_counters {
        my ($self, %options) = @_;

        $self->{maps_counters_type} = [ { name => 'items', type => COUNTER_TYPE_INSTANCE } ];
        $self->{maps_counters}->{items} = [
            { label => 'value', nlabel => 'item.value.count', set => {
                    key_values => [ { name => 'value' } ],
                    output_template => 'value: %s',
                    perfdatas => [ { template => '%s', label_extra_instance => 1 } ]
                }
            }
        ];
    }

    sub manage_selection { $_[0]->{items} = {}; }
}

{
    # COUNTER_TYPE_GROUP: one instance holds data, another has an empty sub block
    package Test::Mode::PartialGroup;
    use base qw(centreon::plugins::templates::counter);
    use centreon::plugins::constants qw(:counters);

    sub set_counters {
        my ($self, %options) = @_;

        $self->{maps_counters_type} = [
            { name => 'servers', type => COUNTER_TYPE_GROUP, message_multiple => 'All servers are ok',
              group => [ { name => 'disks', type => COUNTER_TYPE_INSTANCE } ] }
        ];
        $self->{maps_counters}->{disks} = [
            { label => 'usage', nlabel => 'disk.usage.count', set => {
                    key_values => [ { name => 'usage' } ],
                    output_template => 'usage: %s',
                    perfdatas => [ { template => '%s', label_extra_instance => 1 } ]
                }
            }
        ];
    }

    sub manage_selection {
        my ($self, %options) = @_;

        $self->{servers} = {
            srv1 => { name => 'srv1', disks => { sda => { usage => 10 } } },
            srv2 => { name => 'srv2', disks => {} }
        };
    }
}

{
    # COUNTER_TYPE_GROUP with no instance at all
    package Test::Mode::EmptyGroup;
    use base qw(Test::Mode::PartialGroup);

    sub manage_selection { $_[0]->{servers} = {}; }
}

{
    # COUNTER_TYPE_MULTIPLE with no instance at all
    package Test::Mode::EmptyMultiple;
    use base qw(centreon::plugins::templates::counter);
    use centreon::plugins::constants qw(:counters);

    sub set_counters {
        my ($self, %options) = @_;

        $self->{maps_counters_type} = [
            { name => 'servers', type => COUNTER_TYPE_MULTIPLE, message_multiple => 'All servers are ok',
              group => [ { name => 'disks', type => COUNTER_MULTIPLE_SUBINSTANCE } ] }
        ];
        $self->{maps_counters}->{disks} = [
            { label => 'usage', nlabel => 'disk.usage.count', set => {
                    key_values => [ { name => 'usage' } ],
                    output_template => 'usage: %s',
                    perfdatas => [ { template => '%s', label_extra_instance => 1 } ]
                }
            }
        ];
    }

    sub manage_selection { $_[0]->{servers} = {}; }
}

{
    # COUNTER_TYPE_GROUP holding several instances whose sub blocks are all empty.
    # 'message_multiple' is emitted for >= 2 instances, before any counter runs.
    package Test::Mode::EmptyGroupInstances;
    use base qw(Test::Mode::PartialGroup);

    sub manage_selection {
        my ($self, %options) = @_;

        $self->{servers} = {
            srv1 => { name => 'srv1', disks => {} },
            srv2 => { name => 'srv2', disks => {} }
        };
    }
}

{
    # Same, for COUNTER_TYPE_MULTIPLE
    package Test::Mode::EmptyMultipleInstances;
    use base qw(Test::Mode::EmptyMultiple);

    sub manage_selection {
        my ($self, %options) = @_;

        $self->{servers} = {
            srv1 => { name => 'srv1', disks => {} },
            srv2 => { name => 'srv2', disks => {} }
        };
    }
}

{
    # COUNTER_TYPE_GLOBAL: 'total' is fed, 'missing' is not (NO_VALUE)
    package Test::Mode::Global;
    use base qw(centreon::plugins::templates::counter);
    use centreon::plugins::constants qw(:counters);

    our $DATA = {};

    sub set_counters {
        my ($self, %options) = @_;

        $self->{maps_counters_type} = [ { name => 'stats', type => COUNTER_TYPE_GLOBAL } ];
        $self->{maps_counters}->{stats} = [
            { label => 'total', nlabel => 'item.total.count', set => {
                    key_values => [ { name => 'total' } ],
                    output_template => 'total: %s',
                    perfdatas => [ { template => '%s' } ]
                }
            },
            { label => 'missing', nlabel => 'item.missing.count', set => {
                    key_values => [ { name => 'missing' } ],
                    output_template => 'missing: %s',
                    perfdatas => [ { template => '%s' } ]
                }
            }
        ];
    }

    sub manage_selection { $_[0]->{stats} = { %$DATA }; }
}

{
    # COUNTER_TYPE_GLOBAL whose counters hold values but cannot be computed yet.
    # $CODE is the code the calculation returns: BUFFER_CREATION on the first run of
    # a rate counter, NOT_PROCESSED or a mode specific code ('counter not moved')
    # afterwards. None of them means 'no data'.
    package Test::Mode::PendingGlobal;
    use base qw(centreon::plugins::templates::counter);
    use centreon::plugins::constants qw(:counters :values);

    our $CODE = BUFFER_CREATION;
    our $MESSAGE = 'Buffer creation';
    our $SKIPPED_CODE;

    sub set_counters {
        my ($self, %options) = @_;

        $self->{maps_counters_type} = [
            { name => 'stats', type => COUNTER_TYPE_GLOBAL,
              (defined($SKIPPED_CODE) ? (skipped_code => { $SKIPPED_CODE => 1 }) : ()) }
        ];
        $self->{maps_counters}->{stats} = [
            { label => 'rate', nlabel => 'item.rate.count', set => {
                    key_values => [ { name => 'counter' } ],
                    closure_custom_calc => sub {
                        my ($values) = @_;
                        $values->{error_msg} = $MESSAGE;
                        return $CODE;
                    },
                    output_template => 'rate: %s',
                    perfdatas => [ { template => '%s' } ]
                }
            }
        ];
    }

    sub manage_selection { $_[0]->{stats} = { counter => 42 }; }
}

# --------------------------------------------------------------------------
# Helper: build the mode, run it and hand back the output object.
# 'noexit_die' turns exit() into a die, display() and output_txt() are silenced
# so the test keeps control and the harness output stays clean.
# --------------------------------------------------------------------------

sub run_mode {
    my ($package, @argv) = @_;

    local @ARGV = @argv;

    my $options = centreon::plugins::options->new();
    my $output  = centreon::plugins::output->new(options => $options);
    $options->set_output(output => $output);
    $output->parameter(attr => 'noexit_die', value => 1);

    my $mocked = mock 'centreon::plugins::output' => (
        override => [
            display    => sub { },
            output_txt => sub { }
        ]
    );

    my $mode = $package->new(options => $options, output => $output, mode => 'test');

    # An invalid option makes parse_options() exit, hence the single eval
    eval {
        $options->parse_options();
        $mode->check_options(option_results => $options->get_options());
        $mode->run();
    };

    return $output;
}

# Short message stored for a given severity, undef when there is none.
# Option errors are stored under 'UNQUALIFIED_YET' by add_option_msg().
sub short {
    my ($output, $severity) = @_;

    return $output->{global_short_concat_outputs}->{ uc($severity) };
}

# Severity the plugin would exit with. Messages of a lower severity are never
# displayed, so this is what the user actually sees.
sub status {
    my ($output) = @_;

    return $output->{myerrors}->{ $output->{global_status} };
}

sub long {
    my ($output) = @_;

    return join("\n", @{$output->{global_long_output}});
}

# --------------------------------------------------------------------------
# A mode that collected nothing reports --no-data-status
# --------------------------------------------------------------------------

subtest 'empty instance block reports no data' => sub {
    my $output = run_mode('Test::Mode::EmptyInstance');

    is(short($output, 'unknown'), 'No data!', 'UNKNOWN: No data!');
    is(short($output, 'ok'), undef, 'no empty OK message left behind');
};

subtest 'empty group block reports no data' => sub {
    my $output = run_mode('Test::Mode::EmptyGroup');

    is(short($output, 'unknown'), 'No data!', 'UNKNOWN: No data!');
};

subtest 'empty multiple block reports no data' => sub {
    my $output = run_mode('Test::Mode::EmptyMultiple');

    is(short($output, 'unknown'), 'No data!', 'UNKNOWN: No data!');
};

# 'message_multiple' is emitted before the instance loop, so it reaches the OK
# bucket even when every sub block turns out to be empty. What matters is that it
# never becomes the status the user sees.
subtest 'several group instances with only empty sub blocks report no data' => sub {
    my $output = run_mode('Test::Mode::EmptyGroupInstances');

    is(short($output, 'unknown'), 'No data!', 'UNKNOWN: No data!');
    is(status($output), 'UNKNOWN', "'All servers are ok' does not end up as the exit status");
};

subtest 'several multiple instances with only empty sub blocks report no data' => sub {
    my $output = run_mode('Test::Mode::EmptyMultipleInstances');

    is(short($output, 'unknown'), 'No data!', 'UNKNOWN: No data!');
    is(status($output), 'UNKNOWN', "'All servers are ok' does not end up as the exit status");
};

subtest 'global block whose counters all lack values reports no data' => sub {
    local $Test::Mode::Global::DATA = {};
    my $output = run_mode('Test::Mode::Global');

    is(short($output, 'unknown'), 'No data!', 'UNKNOWN: No data!');
    is(short($output, 'ok'), undef, 'the degenerate OK message is gone');
    like(long($output), qr/skipped \(no value\(s\)\)/, 'the detail moved to the long output');
};

# --------------------------------------------------------------------------
# A mode that collected something is left alone
# --------------------------------------------------------------------------

subtest 'a filled instance inside a group prevents the no data report' => sub {
    my $output = run_mode('Test::Mode::PartialGroup');

    is(short($output, 'unknown'), undef, 'an empty sub block is not a no data case');
    is(short($output, 'ok'), 'All servers are ok', 'the regular message is kept');
};

subtest 'a partially filled global block keeps its short output' => sub {
    local $Test::Mode::Global::DATA = { total => 42 };
    my $output = run_mode('Test::Mode::Global');

    is(short($output, 'unknown'), undef, 'one counter with a value is enough');
    like(short($output, 'ok'), qr/total: 42/, 'the value is displayed');
    like(short($output, 'ok'), qr/missing : skipped \(no value\(s\)\)/, 'the skipped counter is still mentioned');
};

# --------------------------------------------------------------------------
# Counters holding values but not computable yet are not a no data case
# --------------------------------------------------------------------------

subtest 'buffer creation is not a no data case' => sub {
    local $Test::Mode::PendingGlobal::CODE = BUFFER_CREATION;
    local $Test::Mode::PendingGlobal::MESSAGE = 'Buffer creation';
    my $output = run_mode('Test::Mode::PendingGlobal');

    is(short($output, 'unknown'), undef, 'no UNKNOWN on the first run of a rate counter');
    is(short($output, 'ok'), 'rate : Buffer creation', 'the historical message is kept');
};

subtest 'a counter skipped through skipped_code still counts as data' => sub {
    local $Test::Mode::PendingGlobal::CODE = BUFFER_CREATION;
    local $Test::Mode::PendingGlobal::SKIPPED_CODE = BUFFER_CREATION;
    my $output = run_mode('Test::Mode::PendingGlobal');

    is(short($output, 'unknown'), undef, 'a deliberately skipped counter is not a no data case');
    is(short($output, 'ok'), undef, 'and it displays nothing, as before');
};

# --------------------------------------------------------------------------
# --no-data-status
# --------------------------------------------------------------------------

subtest '--no-data-status drives the severity' => sub {
    my %expected = (
        ok       => 'OK',
        warning  => 'WARNING',
        critical => 'CRITICAL',
        unknown  => 'UNKNOWN'
    );

    for my $value (sort keys %expected) {
        my $output = run_mode('Test::Mode::EmptyInstance', "--no-data-status=$value");
        is(short($output, $expected{$value}), 'No data!', "--no-data-status=$value reports $expected{$value}");
    }
};

subtest '--no-data-status defaults to unknown' => sub {
    my $output = run_mode('Test::Mode::EmptyInstance');

    is(short($output, 'unknown'), 'No data!', 'default severity is UNKNOWN');
};

subtest '--no-data-status rejects an unknown value' => sub {
    my $output = run_mode('Test::Mode::EmptyInstance', '--no-data-status=bogus');

    my $msg = short($output, 'UNQUALIFIED_YET');
    like($msg, qr/Bad value provided for option no-data-status/, 'the option is named');
    like($msg, qr/ok, warning, critical, unknown/, 'the accepted values are listed');
    is(short($output, 'unknown'), undef, 'the mode never ran');
};

subtest '--no-data-status rejects an empty value' => sub {
    my $output = run_mode('Test::Mode::EmptyInstance', '--no-data-status=');

    like(
        short($output, 'UNQUALIFIED_YET'),
        qr/Need to specify --no-data-status option/,
        'not_empty rejects an empty value'
    );
};

done_testing();
