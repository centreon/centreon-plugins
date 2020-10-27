#
## Copyright 2020 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s',
        $self->{result_values}->{state},
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
                { name => 'global', type => '0' },
                { name => 'testcases', display_long => 1, cb_prefix_output => 'prefix_testcase_output',  message_multiple => 'test cases are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'testcase-duration', nlabel => 'testcase.duration.milliseconds', set => {
                key_values => [ { name => 'duration' }, { name => 'display' } ],
                output_template => 'duration: %s ms',
                perfdatas => [
                    { template => '%d', unit => 'ms', min => 0, label_extra_instance => 1},
                ],
            }
        },
        { label => 'testcase-state', nlabel => 'testcase.state', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                output_template => 'state: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{testcases} = [
        { label => 'transaction-status', nlabel => 'transaction.state', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
         { label => 'transaction-duration',  nlabel => 'transaction.duration.milliseconds', set => {
                key_values => [ { name => 'duration' }, { name => 'display' } ],
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
        'filter-testcase:s'   => { name => 'filter_testcase' },
    });

    return $self;
}

# sub manage_selection {
#     my ($self, %options) = @_;

#     my $scenarios = $options{custom}->request_api(endpoint => 'testcases');
#     use Data::Dumper; print Dumper($scenarios);

#     foreach my $testcase (values $scenarios->{testcases}) {
#         next if (defined($self->{option_results}->{filter_testcase})
#             && $self->{option_results}->{filter_testcase} ne ''
#             && $testcase->{testcase_alias} !~ /$self->{option_results}->{filter_testcase}/ );
    
#         my $transactions = $options{custom}->request_api(endpoint => 'testcases/' . $testcase->{testcase_alias} . '/');
#         foreach my $step (values $transactions->{measures}) {
#             $self->{cases}->{"hey"}->{total} = $step->{test_case_duration_ms};
#             $self->{cases}->{"hey"}->{"display"} = "display";
#             #use Data::Dumper; print Dumper($transactions);

#         }
#     }

# }

sub manage_selection {
    my ($self, %options) = @_;
    
    use Data::Dumper;
    my $results = $options{custom}->request_api(endpoint => '/testcases/');
    my $i;
    foreach (@{$results->{testcases}}) {
        next if (defined($self->{option_results}->{filter_testcase})
            && $self->{option_results}->{filter_testcase} ne ''
            && $_->{testcase_alias} !~ /$self->{option_results}->{filter_testcase}/ );

        my $measures = $options{custom}->request_api(endpoint => '/testcases/' . $_->{testcase_alias} . '/');
        $i = 1;
        $self->{cases}->{$_->{testcase_alias}} = {
                    display => $_->{testcase_alias},
                    global => {
                        display => $_->{testcase_alias},
                        duration => $measures->{measures}[0]->{test_case_duration_ms},
                        state => $measures->{measures}[0]->{test_case_state}
                    },
                    testcases => {}
        };

        foreach my $transaction (values $measures->{measures}){
            my $instance = $i . '_' . $transaction->{transaction_alias};
            $instance =~ s/ /_/g;
            $self->{cases}->{$_->{testcase_alias}}->{testcases}->{$instance} = {
                display => $instance,
                state => $transaction->{transaction_state},
                duration => $transaction->{transaction_performance_ms}
            };
        $i++;
        }
    }
    print Dumper($self->{cases});
}

    #     }
    #     my $i = 0;
    #     #use Data::Dumper; print Dumper($measures);
    #     foreach my $step (@{$measures->{measures}}) {
    #         $i++;
    #         $self->{case}->{$case->{alias}} = {
    #             state => $step->{test_case_state},
    #             duration => $step->{test_case_duration_ms}
    #         };
    #         $self->{case}->{$case->{alias}}->{steps}->{$i} = {
    #             name => $step->{transaction_alias},
    #             state => $step->{transaction_state},
    #             duration => $step->{transaction_performance_ms}
    #         };
    #     };
    # }



1;

__END__

=head1 MODE

Check Graylog system notifications using Graylog API

Example:
perl centreon_plugins.pl --plugin=apps::graylog::restapi::plugin
--mode=notifications --hostname=10.0.0.1 --username='username' --password='password' --credentials

More information on https://docs.graylog.org/en/<version>/pages/configuration/rest_api.html

=over 8

=item B<--filter-severity>

Filter on specific notification severity.
Can be 'normal' or 'urgent'.
(Default: both severities shown).

=item B<--filter-node>

Filter notifications by node ID.
(Default: all notifications shown).

=item B<--warning-notifications-*>

Set warning threshold for notifications count (Default: '') where '*' can be 'total', 'normal'  or 'urgent'.

=item B<--critical-notifications-*>

Set critical threshold for notifications count (Default: '') where '*' can be 'total', 'normal'  or 'urgent'.

=back

=cut
