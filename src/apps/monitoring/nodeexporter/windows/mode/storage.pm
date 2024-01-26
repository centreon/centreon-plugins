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

package apps::monitoring::nodeexporter::windows::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $value_perf = $self->{result_values}->{used};
    
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{windows_logical_disk_size_bytes};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => 'used', unit => 'B',
        nlabel => 'node.storage.space.free.bytes', 
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{windows_logical_disk_size_bytes},
        instances => $self->{result_values}->{display}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
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

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{windows_logical_disk_size_bytes});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{windows_logical_disk_free_bytes});
    return sprintf(
        "Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{windows_logical_disk_size_bytes} = $options{new_datas}->{$self->{instance} . '_windows_logical_disk_size_bytes'};    
    $self->{result_values}->{windows_logical_disk_free_bytes} = $options{new_datas}->{$self->{instance} . '_windows_logical_disk_free_bytes'};
    $self->{result_values}->{used} = $self->{result_values}->{windows_logical_disk_size_bytes} - $self->{result_values}->{windows_logical_disk_free_bytes};
    $self->{result_values}->{prct_used} = ($self->{result_values}->{windows_logical_disk_size_bytes} > 0) ? $self->{result_values}->{used} * 100 / $self->{result_values}->{windows_logical_disk_size_bytes} : 0;
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    # limit to 100. Better output.
    if ($self->{result_values}->{prct_used} > 100) {
        $self->{result_values}->{windows_logical_disk_free_bytes} = 0;
        $self->{result_values}->{prct_used} = 100;
        $self->{result_values}->{prct_free} = 0;
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'node_storage', type => 1, message_multiple => 'All storages are ok', display_long => 1, cb_prefix_output => 'prefix_storage_output', }
    ];

    $self->{maps_counters}->{node_storage} = [
        { label => 'usage', set => {
                key_values => [ { name => 'windows_logical_disk_free_bytes' }, { name => 'windows_logical_disk_size_bytes' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        }
    ];
}


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "storage:s"     => { name => 'storage' },
        "units:s"       => { name => 'units', default => '%' }
    });

    return $self;
}

sub prefix_storage_output {
    my ($self, %options) = @_;

    return "Storage '" . $options{instance_value}->{display} . "' ";
}


sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
}


sub manage_selection {
    my ($self, %options) = @_;

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");

    foreach my $metric (keys %{$raw_metrics}) {
        next if ($metric !~ /windows_logical_disk_free_bytes|windows_logical_disk_size_bytes/i );

        foreach my $data (@{$raw_metrics->{$metric}->{data}}) {
            next if (defined($self->{option_results}->{storage}) && $data->{dimensions}->{volume} !~ /$self->{option_results}->{storage}/i);

            foreach my $volume ($data->{dimensions}->{volume}) {
                $self->{node_storage}->{$volume}->{$metric} = $data->{value};
                $self->{node_storage}->{$volume}->{display} = $volume;
            }
        }
    }
    
    if (scalar(keys %{$self->{node_storage}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No disk found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check storage based on node exporter metrics.

=over 8

=item B<--storage>

Specify which disk to monitor. Can be a regex.

Default: all disks are monitored.

=item B<--units>

Units of thresholds. Can be : '%', 'B' 
Default: '%'

=item B<--warning-usage>

Warning threshold.

=item B<--critical-usage>

Critical threshold.

=back

=cut