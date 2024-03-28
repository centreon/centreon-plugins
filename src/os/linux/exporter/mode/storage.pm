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

package os::linux::exporter::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my ($label, $nlabel) = ('used', $self->{nlabel});
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        ($label, $nlabel) = ('free', 'storage.space.free.bytes');
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label,
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
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
        "Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
            $total_size_value . " " . $total_size_unit,
            $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
            $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_node_filesystem_size_bytes'};    
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_node_filesystem_free_bytes'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
    $self->{result_values}->{prct_used} = ($self->{result_values}->{total} > 0) ? $self->{result_values}->{used} * 100 / $self->{result_values}->{total} : 0;
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    # limit to 100. Better output.
    if ($self->{result_values}->{prct_used} > 100) {
        $self->{result_values}->{free} = 0;
        $self->{result_values}->{prct_used} = 100;
        $self->{result_values}->{prct_free} = 0;
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'storages',
            type => 1,
            message_multiple => 'All storages are ok',
            cb_prefix_output => 'prefix_storage_output'
        }
    ];

    $self->{maps_counters}->{storages} = [
        {
            label => 'usage',
            nlabel => 'storage.space.usage.bytes',
            set => {
                key_values => [
                    { name => 'node_filesystem_size_bytes' },
                    { name => 'node_filesystem_free_bytes' },
                    { name => 'display' }
                ],
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
        "storage:s" => { name => 'storage' },
        'type:s'    => { name => 'type', default => '^((?!tmpfs|vfat).)*$' },
        "units:s"   => { name => 'units', default => '%' },
        'free'      => { name => 'free' }
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

    $self->{storages} = {};

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(
        filter_metrics => 'node_filesystem_free_bytes|node_filesystem_size_bytes',
        %options
    );

    # node_filesystem_free_bytes{device="/dev/mapper/ol-root",fstype="xfs",mountpoint="/"} 5.7032740864e+10
    # node_filesystem_free_bytes{device="/dev/sda1",fstype="vfat",mountpoint="/boot/efi"} 6.22624768e+08
    # node_filesystem_free_bytes{device="/dev/sda2",fstype="xfs",mountpoint="/boot"} 5.60848896e+08
    # node_filesystem_free_bytes{device="tmpfs",fstype="tmpfs",mountpoint="/run"} 1.886060544e+09
    # node_filesystem_free_bytes{device="tmpfs",fstype="tmpfs",mountpoint="/run/user/10978"} 3.77360384e+08
    # node_filesystem_size_bytes{device="/dev/mapper/ol-root",fstype="xfs",mountpoint="/"} 7.993817088e+10
    # node_filesystem_size_bytes{device="/dev/sda1",fstype="vfat",mountpoint="/boot/efi"} 6.27900416e+08
    # node_filesystem_size_bytes{device="/dev/sda2",fstype="xfs",mountpoint="/boot"} 1.063256064e+09
    # node_filesystem_size_bytes{device="tmpfs",fstype="tmpfs",mountpoint="/run"} 1.88680192e+09
    # node_filesystem_size_bytes{device="tmpfs",fstype="tmpfs",mountpoint="/run/user/10978"} 3.77360384e+08

    foreach my $data (@{$raw_metrics->{node_filesystem_free_bytes}->{data}}) {
        next if (defined($self->{option_results}->{storage}) && $data->{dimensions}->{mountpoint} !~ /$self->{option_results}->{storage}/i);
        next if (defined($self->{option_results}->{type}) && $data->{dimensions}->{fstype} !~ /$self->{option_results}->{type}/i);

        $self->{storages}->{$data->{dimensions}->{mountpoint}}->{node_filesystem_free_bytes} = int($data->{value});
        $self->{storages}->{$data->{dimensions}->{mountpoint}}->{display} = $data->{dimensions}->{mountpoint};
        $self->{storages}->{$data->{dimensions}->{mountpoint}}->{type} = $data->{dimensions}->{fstype};
    }

    foreach my $data (@{$raw_metrics->{node_filesystem_size_bytes}->{data}}) {
        next if (defined($self->{option_results}->{storage}) && $data->{dimensions}->{mountpoint} !~ /$self->{option_results}->{storage}/i);
        next if (defined($self->{option_results}->{type}) && $data->{dimensions}->{fstype} !~ /$self->{option_results}->{type}/i);

        $self->{storages}->{$data->{dimensions}->{mountpoint}}->{node_filesystem_size_bytes} = int($data->{value});
        $self->{storages}->{$data->{dimensions}->{mountpoint}}->{display} = $data->{dimensions}->{mountpoint};
        $self->{storages}->{$data->{dimensions}->{mountpoint}}->{type} = $data->{dimensions}->{fstype};
    }
    
    if (scalar(keys %{$self->{storages}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No storages found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check storages.

=over 8

=item B<--storage>

Specify which disk to monitor. Can be a regex.

Default: all disks are monitored.

=item B<--type>

Filter on type.

Can be used to exclude file system types. 

Default: '^((?!tmpfs|vfat).)*$'

=item B<--units>

Units of thresholds. Can be : '%', 'B' 

Default: '%'

=item B<--warning-usage>

Warning threshold.

=item B<--critical-usage>

Critical threshold.

=back

=cut