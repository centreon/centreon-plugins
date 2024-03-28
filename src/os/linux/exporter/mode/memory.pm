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

package os::linux::exporter::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;

sub custom_ram_perfdata {
    my ($self, %options) = @_;
    
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => 'usage',
        nlabel => 'memory.usage.bytes',
        unit => 'B',
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0,
        max => $self->{result_values}->{total},
    );
}

sub custom_ram_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
    }
    return $self->{perfdata}->threshold_check(
        value => $threshold_value,
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
}

sub custom_ram_output {
    my ($self, %options) = @_;

    return sprintf(
        'Ram Total: %s %s Used (-buffers/cache): %s %s (%.2f%%) Free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub custom_ram_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_node_memory_MemTotal_bytes'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_node_memory_MemFree_bytes'};
    $self->{result_values}->{buffers} = $options{new_datas}->{$self->{instance} . '_node_memory_Buffers_bytes'};
    # Adding cached and swap cached to get the same values as in SNMP, not sure its true but who really knows?
    $self->{result_values}->{cached} = $options{new_datas}->{$self->{instance} . '_node_memory_Cached_bytes'} +
        $options{new_datas}->{$self->{instance} . '_node_memory_SwapCached_bytes'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free} -
        $self->{result_values}->{buffers} - $self->{result_values}->{cached};
    $self->{result_values}->{prct_used} = ($self->{result_values}->{total} > 0) ?
        $self->{result_values}->{used} * 100 / $self->{result_values}->{total} : 0;
    # Actually free
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    
    return 0;
}

sub custom_swap_perfdata {
    my ($self, %options) = @_;
    
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => 'swap',
        nlabel => 'swap.usage.bytes',
        unit => 'B',
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0,
        max => $self->{result_values}->{total},
    );
}

sub custom_swap_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
    }
    return $self->{perfdata}->threshold_check(
        value => $threshold_value,
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
}

sub custom_swap_output {
    my ($self, %options) = @_;
    
    return sprintf(
        'Swap Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub custom_swap_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_node_memory_SwapTotal_bytes'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_node_memory_SwapFree_bytes'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
    $self->{result_values}->{prct_used} = ($self->{result_values}->{total} > 0) ?
        $self->{result_values}->{used} * 100 / $self->{result_values}->{total} : 0;
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    
    return 0;
}

sub custom_cached_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{cached} = $options{new_datas}->{$self->{instance} . '_node_memory_Cached_bytes'} +
        $options{new_datas}->{$self->{instance} . '_node_memory_SwapCached_bytes'};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'ram',
            type => 0,
            skipped_code => { -10 => 1 }
        },
        {
            name => 'swap',
            type => 0,
            skipped_code => { -10 => 1 }
        }
    ];

    $self->{maps_counters}->{ram} = [
        {
            label => 'usage',
            set => {
                key_values => [
                    { name => 'node_memory_MemTotal_bytes' },
                    { name => 'node_memory_MemFree_bytes' },
                    { name => 'node_memory_Buffers_bytes' },
                    { name => 'node_memory_Cached_bytes' },
                    { name => 'node_memory_SwapCached_bytes' }
                ],
                closure_custom_calc => $self->can('custom_ram_calc'),
                closure_custom_output => $self->can('custom_ram_output'),
                closure_custom_perfdata => $self->can('custom_ram_perfdata'),
                closure_custom_threshold_check => $self->can('custom_ram_threshold'),
            }
        },
        { 
            label => 'buffer',
            nlabel => 'memory.buffer.bytes',
            set => {
                key_values => [
                    { name => 'node_memory_Buffers_bytes' }
                ],
                output_template => 'Buffer: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    {
                        template => '%s',
                        min => 0,
                        unit => 'B'
                    }
                ]
            }
        },
        { 
            label => 'cached',
            nlabel => 'memory.cached.bytes',
            set => {
                key_values => [
                    { name => 'node_memory_Cached_bytes' },
                    { name => 'node_memory_SwapCached_bytes' }
                ],
                closure_custom_calc => $self->can('custom_cached_calc'),
                output_template => 'Cached: %.2f %s',
                output_change_bytes => 1,
                output_use => 'cached',
                threshold_use => 'cached',
                perfdatas => [
                    {
                        value => 'cached',
                        template => '%s',
                        min => 0,
                        unit => 'B'
                    }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{swap} = [
        {
            label => 'swap',
            set => {
                key_values => [
                    { name => 'node_memory_SwapTotal_bytes' },
                    { name => 'node_memory_SwapFree_bytes' },
                    { name => 'node_memory_SwapCached_bytes' }
                ],
                closure_custom_calc => $self->can('custom_swap_calc'),
                closure_custom_output => $self->can('custom_swap_output'),
                closure_custom_perfdata => $self->can('custom_swap_perfdata'),
                closure_custom_threshold_check => $self->can('custom_swap_threshold'),
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
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(
        filter_metrics => 'node_memory_Mem|node_memory_Cached_bytes|node_memory_Buffers_bytes|node_memory_Swap',
        %options
    );

    # node_memory_Buffers_bytes 4.419584e+06
    # node_memory_Cached_bytes 1.69089024e+09
    # node_memory_MemAvailable_bytes 1.971458048e+09
    # node_memory_MemFree_bytes 4.52554752e+08
    # node_memory_MemTotal_bytes 3.77360384e+09
    # node_memory_SwapCached_bytes 8.4508672e+07
    # node_memory_SwapFree_bytes 3.433295872e+09
    # node_memory_SwapTotal_bytes 4.227854336e+09

    foreach my $metric (keys %{$raw_metrics}) {
        $self->{ram}->{$metric} = int($raw_metrics->{$metric}->{data}[0]->{value});
        $self->{swap}->{$metric} = int($raw_metrics->{$metric}->{data}[0]->{value});
    }

    if (scalar(keys %{$self->{ram}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check memory and swap usages.

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