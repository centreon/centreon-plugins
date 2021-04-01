#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package cloud::prometheus::exporters::nodeexporter::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 3, cb_prefix_output => 'prefix_node_output', cb_long_output => 'node_long_output',
          message_multiple => 'All nodes usage are ok', indent_long_output => '    ',
            group => [
                { name => 'global_cpu', cb_prefix_output => 'prefix_global_cpu_output', type => 0, skipped_code => { -10 => 1 } },
                { name => 'cpu', display_long => 1, cb_prefix_output => 'prefix_cpu_output',
                  message_multiple => 'All CPUs usage are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];
    
    $self->{maps_counters}->{global_cpu} = [
        { label => 'node-usage', nlabel => 'node.cpu.utilization.percentage', set => {
                key_values => [ { name => 'node_average' } ],
                output_template => '%.2f %%',
                perfdatas => [
                    { label => 'node', value => 'node_average', template => '%.2f', unit => '%', 
                      min => 0, max => 100, label_extra_instance => 1 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-usage', nlabel => 'core.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_usage' }, { name => 'display' } ],
                output_template => 'Usage: %.2f %%',
                perfdatas => [
                    { label => 'cpu', value => 'cpu_usage', template => '%.2f', unit => '%', 
                      min => 0, max => 100, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub node_long_output {
    my ($self, %options) = @_;

    return "Checking node '" . $options{instance_value}->{display} . "'";
}

sub prefix_global_cpu_output {
    my ($self, %options) = @_;

    return "CPU Average Usage: ";
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "instance:s"            => { name => 'instance', default => 'instance=~".*"' },
        "cpu:s"                 => { name => 'cpu', default => 'cpu=~".*"' },
        "extra-filter:s@"       => { name => 'extra_filter' },
        "metric-overload:s@"    => { name => 'metric_overload' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{metrics} = {
        'cpu' => "^node_cpu.*",
    };
    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }

    $self->{labels} = {};
    foreach my $label (('instance', 'cpu')) {
        if ($self->{option_results}->{$label} !~ /^(\w+)[!~=]+\".*\"$/) {
            $self->{output}->add_option_msg(short_msg => "Need to specify --" . $label . " option as a PromQL filter.");
            $self->{output}->option_exit();
        }
        $self->{labels}->{$label} = $1;
    }

    $self->{extra_filter} = '';
    foreach my $filter (@{$self->{option_results}->{extra_filter}}) {
        $self->{extra_filter} .= ',' . $filter;
    }

    $self->{prom_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{prom_step} = defined($self->{option_results}->{step}) ? $self->{option_results}->{step} : "5m";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};

    my $results = $options{custom}->query_range(
        queries => [
            '(1 - irate({__name__=~"' . $self->{metrics}->{cpu} . '",' . 
                'mode="idle",' .
                $self->{option_results}->{instance} . ',' .
                $self->{option_results}->{cpu} .
                $self->{extra_filter} . '}[' . $self->{prom_step} . '])) * 100'
        ],
        timeframe => $self->{prom_timeframe}, step => $self->{prom_step}
    );

    foreach my $result (@{$results}) {
        my $average = $options{custom}->compute(aggregation => 'average', values => $result->{values});
        $self->{nodes}->{$result->{metric}->{$self->{labels}->{instance}}}->{display} = $result->{metric}->{$self->{labels}->{instance}},
        $self->{nodes}->{$result->{metric}->{$self->{labels}->{instance}}}->{global_cpu}->{node_average} += $average;
        $self->{nodes}->{$result->{metric}->{$self->{labels}->{instance}}}->{cpu}->{$result->{metric}->{$self->{labels}->{cpu}}}->{display} = $result->{metric}->{$self->{labels}->{cpu}};
        $self->{nodes}->{$result->{metric}->{$self->{labels}->{instance}}}->{cpu}->{$result->{metric}->{$self->{labels}->{cpu}}}->{cpu_usage} = $average;
    }    

    foreach my $node (keys %{$self->{nodes}}) {
        $self->{nodes}->{$node}->{global_cpu}->{node_average} /= scalar(keys %{$self->{nodes}->{$node}->{cpu}});
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

=item B<--instance>

Filter on a specific instance (Must be a PromQL filter, Default: 'instance=~".*"')

=item B<--cpu>

Filter on a specific cpu (Must be a PromQL filter, Default: 'cpu=~".*"')

=item B<--warning-*>

Threshold warning.
Can be: 'node-usage', 'cpu-usage'.

=item B<--critical-*>

Threshold critical.
Can be: 'node-usage', 'cpu-usage'.

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple)

Example : --metric-overload='metric,^my_metric_name$'

Default :

    - cpu: ^node_cpu.*

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='node'

=back

=cut
