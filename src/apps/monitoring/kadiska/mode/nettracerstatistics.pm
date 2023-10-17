#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package apps::monitoring::kadiska::mode::nettracerstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_output {
    my ($self, %options) = @_;
    
    return "Target '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'targets', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All targets are OK' }
    ];

    $self->{maps_counters}->{targets} = [
        { label => 'round-trip', nlabel => 'tracer.round.trip.persecond', set => {
                key_values => [ { name => 'round_trip' }, { name => 'instance' }, { name => 'runner_name' } ],
                output_template => 'round trip: %.2f ms',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => 'ms',
                        instances => [$self->{result_values}->{instance}, $self->{result_values}->{runner_name}],
                        value => sprintf('%.2f', $self->{result_values}->{round_trip}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'path-length', nlabel => 'tracer.path.length', set => {
                key_values => [ { name => 'path_length' }, { name => 'instance' }, { name => 'runner_name' } ],
                output_template => 'path length: %.2f',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        instances => [$self->{result_values}->{instance}, $self->{result_values}->{runner_name}],
                        value => sprintf('%.2f', $self->{result_values}->{path_length}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0
                    );
                }
            }
        },
        { label => 'packets-loss-prct', nlabel => 'tracer.packets.loss.percentage', set => {
                key_values => [ { name => 'packets_loss_prct' }, { name => 'instance' }, { name => 'runner_name' } ],
                output_template => 'packets loss: %.2f %%',
                closure_custom_perfdata => sub {
                    my ($self, %options) = @_;

                    $self->{output}->perfdata_add(
                        nlabel => $self->{nlabel},
                        unit => '%',
                        instances => [$self->{result_values}->{instance}, $self->{result_values}->{runner_name}],
                        value => sprintf('%.2f', $self->{result_values}->{packets_loss_prct}),
                        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
                        min => 0,
                        max => 100
                    );
                }
            }
        }          
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-runner-name:s' => { name => 'filter_runner_name' },
        'filter-target-name:s' => { name => 'filter_target_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_form_post = {
        "select" => [
            {
                "target:group" => "target_name"
            },
            {
                "length_furthest:avg" => ["avg","length_furthest"]
            },
            {
                "loss_furthest:avg" => ["*",100, ["avg","loss_furthest"] ]
            },
            {
                "rtt_furthest:avg" => ["avg","rtt_furthest"]
            }
        ],
        "from" => "traceroute",
        "groupby" => [
            "target:group"
        ],
        "orderby" => [
            ["rtt_furthest:avg","desc"]
        ],
        "offset" => 0,
        "options" => {"sampling" => \1 }
    };  

    my $runner_name = 'runner:all';
    if (defined($self->{option_results}->{filter_runner_name}) && $self->{option_results}->{filter_runner_name} ne ''){
        $raw_form_post->{where} = ["=", "runner_name", ["\$", $self->{option_results}->{filter_runner_name}]];
        $runner_name = $self->{option_results}->{filter_runner_name};
    }

    my $results = $options{custom}->request_api(
        method => 'POST',
        endpoint => 'query',
        query_form_post => $raw_form_post
    );

    $self->{targets} = {};
    foreach my $runner (@{$results->{data}}) {
        next if (defined($self->{option_results}->{filter_target_name}) && $self->{option_results}->{filter_target_name} ne ''
            && $runner->{'target:group'} !~ /^$self->{option_results}->{filter_target_name}$/);

        my $instance = $runner->{"target:group"};

        $self->{targets}->{$instance} = {
            instance => $instance,
            runner_name => $runner_name,
            round_trip => ($runner->{'rtt_furthest:avg'} / 1000),
            packets_loss_prct => $runner->{'loss_furthest:avg'},
            path_length => $runner->{'length_furthest:avg'}
        };
    };

    if (scalar(keys %{$self->{targets}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No instances or results found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Kadiska net tracer targets' statistics during the period specified.

=over 8

=item B<--filter-runner-name>

Filter on runner name to display net tracer targets' statistics linked to a particular runner. 

=item B<--filter-target-name>

Filter to display statistics for particular net tracer targets. Can be a regex or a single tracer target.
A target name must be given. 

Regex example: 
--filter-target-name="(mylab.com|shop.mylab.com)"

=item B<--warning-round-trip>

Warning threshold for round trip in milliseconds.

=item B<--critical-round-trip>

Critical threshold for round trip in milliseconds.

=item B<--warning-path-length>

Warning threshold for path length to reach targets. 

=item B<--critical-path-length>

Critical threshold for path length to reach targets. 

=item B<--warning-packets-loss-prct>

Warning threshold for packets' loss in percentage. 

=item B<--critical-packets-loss-prct>

Critical threshold for packets' loss in percentage. 

=back

=cut
