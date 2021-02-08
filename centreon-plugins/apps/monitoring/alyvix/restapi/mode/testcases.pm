#
## Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package apps::monitoring::alyvix::restapi::mode::testcases;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use POSIX qw(strftime);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s',
        $self->{result_values}->{state}
    );
}

sub custom_date_output {
    my ($self, %options) = @_;

    return sprintf(
        'last execution: %s (%s ago)',
        $self->{result_values}->{lastexec},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{freshness})
    );
}

sub testcase_long_output {
    my ($self, %options) = @_;

    return "checking test case '" . $options{instance_value}->{display} . "'";
}

sub prefix_testcases_output {
    my ($self, %options) = @_;

    return "test case '" . $options{instance_value}->{display} . "' ";
}

sub prefix_testcase_output {
    my ($self, %options) = @_;

    return "transaction '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cases', type => 3, cb_prefix_output => 'prefix_testcases_output', cb_long_output => 'testcase_long_output', indent_long_output => '    ', message_multiple => 'All test cases are ok',
            group => [
                { name => 'global', type => 0 },
                { name => 'testcases', display_long => 1, cb_prefix_output => 'prefix_testcase_output',  message_multiple => 'test cases are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'testcase-duration', nlabel => 'testcase.duration.milliseconds', set => {
                key_values => [ { name => 'duration' } ],
                output_template => 'duration: %s ms',
                perfdatas => [
                    { template => '%d', unit => 'ms', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'testcase-state', type => 2, critical_default => '%{state} eq "FAILED"', set => {
                key_values => [ { name => 'state' }],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'testcase-freshness', nlabel => 'testcase.freshness.seconds', set => {
                key_values => [ { name => 'freshness' }, { name => 'lastexec' } ],
                closure_custom_output => $self->can('custom_date_output'),
                perfdatas => [
                    { template => '%.3f', unit => 's', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{testcases} = [
        { label => 'transaction-state', type => 2, critical_default => '%{state} eq "FAILED"', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'transaction-duration',  nlabel => 'transaction.duration.milliseconds', set => {
                key_values => [ { name => 'duration' } ],
                output_template => 'duration: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-testcase:s' => { name => 'filter_testcase' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $status = { 0 => 'OK', 2 => 'FAILED' };
    my $results = $options{custom}->request_api(endpoint => '/testcases/');
    foreach (@{$results->{testcases}}) {
        next if (
            defined($self->{option_results}->{filter_testcase})
            && $self->{option_results}->{filter_testcase} ne ''
            && $_->{testcase_alias} !~ /$self->{option_results}->{filter_testcase}/
        );

        my $measures = $options{custom}->request_api(endpoint => '/testcases/' . $_->{testcase_alias} . '/');
        my $lastexec = $measures->{measures}->[0]->{timestamp_epoch} / 1000000000;
        $self->{cases}->{ $_->{testcase_alias} } = {
            display => $_->{testcase_alias},
            global => {
                display   => $_->{testcase_alias},
                duration  => $measures->{measures}->[0]->{test_case_duration_ms},
                state     => $status->{ $measures->{measures}->[0]->{test_case_state} },
                lastexec  => strftime('%Y-%m-%dT%H:%M:%S', localtime($lastexec)),
                freshness => (time() - $lastexec)
            },
            testcases => {}
        };

        my $i = 1;
        foreach my $transaction (@{$measures->{measures}}) {
            my $instance = $i . '_' . $transaction->{transaction_alias};
            $instance =~ s/ /_/g;
            $self->{cases}->{ $_->{testcase_alias} }->{testcases}->{$instance} = {
                display  => $instance,
                state    => $status->{ $transaction->{transaction_state} },
                duration => $transaction->{transaction_performance_ms}
            };
            $i++;
        }
    }

    if (scalar(keys %{$self->{cases}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No test case found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Alyvix Server test cases using Alyvix Rest API

Example:
perl centreon_plugins.pl --plugin=apps::monitoring::alyvix::restapi::plugin --mode=testcases --hostname='10.0.0.1'

=over 8

=item B<--filter-testcase>

Filter on specific test case.

=item B<--warning-*-state>

Set warning status (Default: '') where '*' can be 'testcase' or 'transaction'.

=item B<--critical-*-state>

Set critical status (Default: '%{state} eq "FAILED"') where '*' can be 'testcase' or 'transaction'.

=item B<--warning-*-duration>

Set warning threshold for test cases or transactions duration (Default: '') where '*' can be 'testcase' or 'transaction'. 

=item B<--critical-*-duration>

Set critical threshold for test cases or transactions duration (Default: '') where '*' can be 'testcase' or 'transaction'.

=back

=cut
