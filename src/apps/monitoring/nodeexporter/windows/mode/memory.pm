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

package apps::monitoring::nodeexporter::windows::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;

# memory usage calculation

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{windows_os_virtual_memory_bytes};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        nlabel => 'node.memory.usage.bytes', 
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{windows_os_virtual_memory_bytes},
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

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{windows_os_virtual_memory_bytes});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my $msg = sprintf("Ram Total: %s, Used: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{windows_os_virtual_memory_bytes} = $options{new_datas}->{node_memory_windows_os_virtual_memory_bytes};
    $self->{result_values}->{windows_os_virtual_memory_free_bytes} = $options{new_datas}->{node_memory_windows_os_virtual_memory_free_bytes};
    $self->{result_values}->{used} = $self->{result_values}->{windows_os_virtual_memory_bytes} - $self->{result_values}->{windows_os_virtual_memory_free_bytes};
    $self->{result_values}->{prct_used} = ($self->{result_values}->{windows_os_virtual_memory_bytes} > 0) ? $self->{result_values}->{used} * 100 / $self->{result_values}->{windows_os_virtual_memory_bytes} : 0;
    
    return 0;
}

# paging usage calculation

sub custom_paging_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{windows_os_paging_limit_bytes};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        nlabel => 'node.paging.usage.bytes', 
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{windows_os_paging_limit_bytes},
    );
}

sub custom_paging_usage_threshold {
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

sub custom_paging_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{windows_os_paging_limit_bytes});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my $msg = sprintf("Paging Total size: %s, Used: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used});
    return $msg;
}

sub custom_paging_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{windows_os_paging_limit_bytes} = $options{new_datas}->{node_memory_windows_os_paging_limit_bytes};
    $self->{result_values}->{windows_os_paging_free_bytes} = $options{new_datas}->{node_memory_windows_os_paging_free_bytes};
    $self->{result_values}->{used} = $self->{result_values}->{windows_os_paging_limit_bytes} - $self->{result_values}->{windows_os_paging_free_bytes};
    $self->{result_values}->{prct_used} = ($self->{result_values}->{windows_os_paging_limit_bytes} > 0) ? $self->{result_values}->{used} * 100 / $self->{result_values}->{windows_os_paging_limit_bytes} : 0;
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'node_memory', type => 0, message_multiple => 'All memory types are ok' }
    ];

    $self->{maps_counters}->{node_memory} = [
        { label => 'usage', set => {
                key_values => [ { name => 'windows_os_virtual_memory_bytes' }, { name => 'windows_os_virtual_memory_free_bytes' }],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { 
            label => 'paging', nlabel => 'node.memory.pages.bytes', set => {
                key_values => [ { name => 'windows_os_paging_limit_bytes'  }, { name => 'windows_os_paging_free_bytes'  } ],
                closure_custom_calc => $self->can('custom_paging_usage_calc'),
                closure_custom_output => $self->can('custom_paging_usage_output'),
                closure_custom_perfdata => $self->can('custom_paging_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_paging_usage_threshold')
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
        next if ($metric !~ /windows_os_virtual_memory_free_bytes|windows_os_virtual_memory_bytes|windows_os_paging_free_bytes|windows_os_paging_limit_bytes/i);

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

=item B<--warning-usage>

Warning threshlod.

=item B<--critical-usage>

Critical threshlod.

=item B<--warning-paging>

Warning threshlod.

=item B<--critical-paging>

Critical threshlod.

=back

=cut