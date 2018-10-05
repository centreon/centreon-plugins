#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package cloud::prometheus::exporters::nodeexporter::mode::load;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_nodes_output', message_multiple => 'All nodes load are ok' },
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'load1', set => {
                key_values => [ { name => 'node_load1' }, { name => 'display' } ],
                output_template => 'Load 1 minute: %.2f',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'load1', value => 'node_load1_absolute', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'load5', set => {
                key_values => [ { name => 'node_load5' }, { name => 'display' } ],
                output_template => 'Load 5 minutes: %.2f',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'load5', value => 'node_load5_absolute', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'load15', set => {
                key_values => [ { name => 'node_load15' }, { name => 'display' } ],
                output_template => 'Load 15 minutes: %.2f',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'load15', value => 'node_load15_absolute', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_nodes_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "filter:s"            => { name => 'filter', default => '' },
                                });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};
    $self->{cpu} = {};

    my $filter = (defined($self->{option_results}->{filter}) && $self->{option_results}->{filter} ne '') ? $self->{option_results}->{filter} . ',' : '';

    my $results = $options{custom}->query_range(queries => [ "node_load1{" . $filter . "}", "node_load5{" . $filter . "}",
                                                             "node_load15{" . $filter . "}" ]);
    
    foreach my $metric (@{$results}) {
        my $average = $options{custom}->compute(aggregation => 'average', values => $metric->{values});
        $self->{nodes}->{$metric->{metric}->{instance}}->{display} = $metric->{metric}->{instance};
        $self->{nodes}->{$metric->{metric}->{instance}}->{$metric->{metric}->{__name__}} = $average;
    }
    
    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No nodes found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check CPU usage for nodes and each of their cores.

=over 8

=item B<--filter>

Set a PromQL filter (Example : 'instance=~".*master.*"')

=item B<--warning-*>

Threshold warning.
Can be: 'node-usage', 'cpu-usage'.

=item B<--critical-*>

Threshold critical.
Can be: 'node-usage', 'cpu-usage'.

=back

=cut
