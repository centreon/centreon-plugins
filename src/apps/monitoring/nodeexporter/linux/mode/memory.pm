#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::monitoring::nodeexporter::linux::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{node_memory_node_memory_MemTotal_bytes};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        nlabel => 'node.memory.usage.bytes', 
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{node_memory_node_memory_MemTotal_bytes},
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                              { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{node_memory_node_memory_MemTotal_bytes});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my $msg = sprintf("Ram Total: %s, Used (-buffers/cache): %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{node_memory_node_memory_MemTotal_bytes} = $options{new_datas}->{node_memory_node_memory_MemTotal_bytes};
    $self->{result_values}->{node_memory_node_memory_MemFree_bytes} = $options{new_datas}->{node_memory_node_memory_MemFree_bytes};
    $self->{result_values}->{node_memory_node_memory_Buffers_bytes} = $options{new_datas}->{node_memory_node_memory_Buffers_bytes};
    $self->{result_values}->{node_memory_node_memory_Cached_bytes} = $options{new_datas}->{node_memory_node_memory_Cached_bytes};
    $self->{result_values}->{used} = $self->{result_values}->{node_memory_node_memory_MemTotal_bytes} - $self->{result_values}->{node_memory_node_memory_MemFree_bytes} - $self->{result_values}->{node_memory_node_memory_Buffers_bytes} - $self->{result_values}->{node_memory_node_memory_Cached_bytes};
    $self->{result_values}->{prct_used} = ($self->{result_values}->{node_memory_node_memory_MemTotal_bytes} > 0) ? $self->{result_values}->{used} * 100 / $self->{result_values}->{node_memory_node_memory_MemTotal_bytes} : 0;
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'node_memory', type => 0, message_multiple => 'All memory types are ok' }
    ];

    $self->{maps_counters}->{node_memory} = [
        { label => 'usage', set => {
                key_values => [ { name => 'node_memory_MemTotal_bytes' }, { name => 'node_memory_MemFree_bytes' }, { name => 'node_memory_Buffers_bytes'  }, { name => 'node_memory_Cached_bytes' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { 
            label => 'buffer', nlabel => 'node.memory.buffer.bytes', set => {
                key_values => [ { name => 'node_memory_Buffers_bytes'  } ],
                output_template => 'Buffer: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'node_memory_Buffers_bytes', template => '%s',
                      min => 0, unit => 'B' }
                ]
            }
        },
        { 
            label => 'cached', nlabel => 'node.memory.cached.bytes', set => {
                key_values => [ { name => 'node_memory_Cached_bytes' } ],
                output_template => 'Cached: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'node_memory_Cached_bytes', template => '%s',
                      min => 0, unit => 'B' }
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
        "units:s"     => { name => 'units', default => '%' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");

    foreach my $metric (keys %{$raw_metrics}) {
        next if ($metric !~ /node_memory_MemTotal_bytes|node_memory_MemFree_bytes|node_memory_Cached_bytes|node_memory_Buffers_bytes/i);

        $self->{node_memory}->{$metric} = $raw_metrics->{$metric}->{data}[0]->{value};
    }
    if (scalar(keys %{$self->{node_memory}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check memory based on node exporter metrics.

=over 8

=item B<--units>

Units of thresholds. Can be : '%', 'B' 
Default: '%'

=item B<--warning-*>

Warning threshold.

Can be: 'usage', 'buffer', 'cached'.

=item B<--critical-*>

Critical threshold.

Can be: 'usage', 'buffer', 'cached'.

=back

=cut