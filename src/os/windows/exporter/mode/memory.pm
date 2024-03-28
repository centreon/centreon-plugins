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

package os::windows::exporter::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my ($label, $nlabel) = ('used', $self->{nlabel});
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        ($label, $nlabel) = ('free', 'memory.free.bytes');
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label,
        unit => 'B',
        nlabel => $nlabel,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0,
        max => $self->{result_values}->{total},
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value,
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        "Ram Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
            $total_size_value . " " . $total_size_unit,
            $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
            $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_windows_os_virtual_memory_bytes'} - $options{new_datas}->{$self->{instance} . '_windows_os_paging_limit_bytes'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_windows_os_virtual_memory_free_bytes'} - $options{new_datas}->{$self->{instance} . '_windows_os_paging_limit_bytes'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
    $self->{result_values}->{prct_used} = ($self->{result_values}->{used} > 0) ? $self->{result_values}->{used} * 100 / $self->{result_values}->{total} : 0;
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    
    return 0;
}

sub custom_paging_perfdata {
    my ($self, %options) = @_;
    
    my ($label, $nlabel) = ('paging-used', $self->{nlabel});
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        ($label, $nlabel) = ('paging-free', 'paging.free.bytes');
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label,
        unit => 'B',
        nlabel => $nlabel,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0,
        max => $self->{result_values}->{total},
    );
}

sub custom_paging_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value,
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_paging_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        "Paging Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
            $total_size_value . " " . $total_size_unit,
            $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
            $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_paging_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_windows_os_paging_limit_bytes'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_windows_os_paging_free_bytes'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
    $self->{result_values}->{prct_used} = ($self->{result_values}->{used} > 0) ? $self->{result_values}->{used} * 100 / $self->{result_values}->{total} : 0;
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'usage',
            nlabel => 'memory.usage.bytes',
            set => {
                key_values => [
                    { name => 'windows_os_virtual_memory_bytes' },
                    { name => 'windows_os_virtual_memory_free_bytes' },
                    { name => 'windows_os_paging_limit_bytes' }
                ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { 
            label => 'paging',
            nlabel => 'paging.usage.bytes',
            set => {
                key_values => [
                    { name => 'windows_os_paging_limit_bytes' },
                    { name => 'windows_os_paging_free_bytes' }
                ],
                closure_custom_calc => $self->can('custom_paging_calc'),
                closure_custom_output => $self->can('custom_paging_output'),
                closure_custom_perfdata => $self->can('custom_paging_perfdata'),
                closure_custom_threshold_check => $self->can('custom_paging_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "units:s" => { name => 'units', default => '%' },
        'free'    => { name => 'free' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        windows_os_virtual_memory_bytes => 0,
        windows_os_virtual_memory_free_bytes => 0,
        windows_os_paging_free_bytes => 0,
        windows_os_paging_limit_bytes => 0
    };

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(
        filter_metrics => 'windows_os_virtual_memory|windows_os_paging',
        %options
    );

    # windows_os_virtual_memory_bytes 9.931087872e+09
    # windows_os_virtual_memory_free_bytes 7.240609792e+09
    # windows_os_paging_free_bytes 1.115664384e+09
    # windows_os_paging_limit_bytes 1.34217728e+09

    $self->{global}->{windows_os_virtual_memory_bytes} = int($raw_metrics->{windows_os_virtual_memory_bytes}->{data}[0]->{value});
    $self->{global}->{windows_os_virtual_memory_free_bytes} = int($raw_metrics->{windows_os_virtual_memory_free_bytes}->{data}[0]->{value});
    $self->{global}->{windows_os_paging_free_bytes} = int($raw_metrics->{windows_os_paging_free_bytes}->{data}[0]->{value});
    $self->{global}->{windows_os_paging_limit_bytes} = int($raw_metrics->{windows_os_paging_limit_bytes}->{data}[0]->{value});
}

1;

__END__

=head1 MODE

Check memory usage.

Uses metrics from https://github.com/prometheus-community/windows_exporter/blob/master/docs/collector.os.md.

=over 8

=item B<--units>

Units of thresholds (default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--warning-*> B<--critical-*>

Warning threshold.

Can be: 'usage', 'paging'.

=back

=cut