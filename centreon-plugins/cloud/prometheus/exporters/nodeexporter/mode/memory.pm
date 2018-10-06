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

package cloud::prometheus::exporters::nodeexporter::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $instance_mode;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{display} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    my %total_options = ();
    if ($instance_mode->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => $label . $extra_label, unit => 'B',
                                  value => $value_perf,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    if ($instance_mode->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                                                         { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my $msg = sprintf("Ram Total: %s, Used (-buffers/cache): %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_node_memory_MemTotal_bytes'};
    $self->{result_values}->{available} = $options{new_datas}->{$self->{instance} . '_node_memory_MemAvailable_bytes'};
    $self->{result_values}->{buffer} = $options{new_datas}->{$self->{instance} . '_node_memory_Buffers_bytes'};
    $self->{result_values}->{cached} = $options{new_datas}->{$self->{instance} . '_node_memory_Cached_bytes'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{available} - $self->{result_values}->{buffer} - $self->{result_values}->{cached};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / ($self->{result_values}->{total});
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_nodes_output', message_multiple => 'All nodes memory usage are ok' },
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'usage', set => {
                key_values => [ { name => 'node_memory_MemTotal_bytes' }, { name => 'node_memory_MemAvailable_bytes' },
                    { name => 'node_memory_Buffers_bytes' }, { name => 'node_memory_Cached_bytes' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'buffer', set => {
                key_values => [ { name => 'node_memory_Buffers_bytes' }, { name => 'display' } ],
                output_template => 'Buffer: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'buffer', value => 'node_memory_Buffers_bytes_absolute', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'cached', set => {
                key_values => [ { name => 'node_memory_Cached_bytes' }, { name => 'display' } ],
                output_template => 'Cached: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'cached', value => 'node_memory_Cached_bytes_absolute', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display_absolute' },
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
                                  "node:s"                  => { name => 'node', default => '.*' },
                                  "extra-filter:s@"         => { name => 'extra_filter' },
                                  "units:s"                 => { name => 'units', default => '%' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $instance_mode = $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};

    my $extra_filter = '';
    foreach my $filter (@{$self->{option_results}->{extra_filter}}) {
        $extra_filter .= ',' . $filter;
    }

    my $results = $options{custom}->query_range(queries => [ 'node_memory_MemTotal_bytes{instance=~"' . $self->{option_results}->{node} .
                                                            '"' . $extra_filter . '}',
                                                            'node_memory_MemAvailable_bytes{instance=~"' . $self->{option_results}->{node} .
                                                            '"' . $extra_filter . '}',
                                                            'node_memory_Cached_bytes{instance=~"' . $self->{option_results}->{node} .
                                                            '"' . $extra_filter . '}',
                                                            'node_memory_Buffers_bytes{instance=~"' . $self->{option_results}->{node} .
                                                            '"' . $extra_filter . '}' ]);
    
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

Check memory usage.

=over 8

=item B<--node>

Filter on a specific node (Must be a regexp)

=item B<--extra-filter>

Set a PromQL filter (Can be multiple, Example : 'name=~".*pretty.*"')

=item B<--warning-*>

Threshold warning.
Can be: 'usage', 'buffer', 'cached'.

=item B<--critical-*>

Threshold critical.
Can be: 'usage', 'buffer', 'cached'.

=back

=cut
