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

package cloud::prometheus::exporters::nodeexporter::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $instance_mode;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($instance_mode->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }
    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{multi} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    $extra_label .= '_' . $self->{result_values}->{display} if (!defined($options{extra_instance_lvl2}) || $options{extra_instance_lvl2} != 0);
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
    $threshold_value = $self->{result_values}->{free} if (defined($instance_mode->{option_results}->{free}));
    if ($instance_mode->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($instance_mode->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{multi} = $options{new_datas}->{$self->{instance} . '_multi'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_size'};    
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
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
        { name => 'nodes', type => 3, cb_prefix_output => 'prefix_nodes_output', message_multiple => 'All nodes storages usage are ok',
          counters => [ { name => 'storage', type => 1, cb_prefix_output => 'prefix_storage_output', message_multiple => 'All storages usage are ok' } ] },
    ];

    $self->{maps_counters}->{storage} = [
        { label => 'usage', set => {
                key_values => [ { name => 'free' }, { name => 'size' }, { name => 'multi' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_nodes_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "'";
}

sub prefix_storage_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{multi} . "' Storage '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "node:s"                  => { name => 'node', default => '.*' },
                                  "storage:s"               => { name => 'storage', default => '.*' },
                                  "exclude-storage-type:s"  => { name => 'exclude_storage_type', default => 'rootfs|tmpfs' },
                                  "extra-filter:s@"         => { name => 'extra_filter' },
                                  "units:s"                 => { name => 'units', default => '%' },
                                  "free"                    => { name => 'free' },
                                  "metric-overload:s@"      => { name => 'metric_overload' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{metrics} = {
        'free'      => "^node_filesystem_free.*",
        'size'      => "^node_filesystem_size.*",
    };

    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }
    
    $instance_mode = $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};

    my $extra_filter = '';
    foreach my $filter (@{$self->{option_results}->{extra_filter}}) {
        $extra_filter .= ',' . $filter;
    }

    my $results = $options{custom}->query(queries => [ 'label_replace({__name__=~"' . $self->{metrics}->{free} . '",instance=~"' . $self->{option_results}->{node} .
                                                        '",mountpoint=~"' . $self->{option_results}->{storage} .
                                                        '",fstype!~"' . $self->{option_results}->{exclude_storage_type} .
                                                        '"' . $extra_filter . '}, "__name__", "free", "", "")',
                                                       'label_replace({__name__=~"' . $self->{metrics}->{size} . '",instance=~"' . $self->{option_results}->{node} .
                                                        '",mountpoint=~"' . $self->{option_results}->{storage} .
                                                        '",fstype!~"' . $self->{option_results}->{exclude_storage_type} .
                                                        '"' . $extra_filter . '}, "__name__", "size", "", "")' ]);
    
    foreach my $metric (@{$results}) {
        $self->{nodes}->{$metric->{metric}->{instance}}->{display} = $metric->{metric}->{instance};
        $self->{nodes}->{$metric->{metric}->{instance}}->{storage}->{$metric->{metric}->{mountpoint}}->{multi} = $metric->{metric}->{instance};
        $self->{nodes}->{$metric->{metric}->{instance}}->{storage}->{$metric->{metric}->{mountpoint}}->{display} = $metric->{metric}->{mountpoint};
        $self->{nodes}->{$metric->{metric}->{instance}}->{storage}->{$metric->{metric}->{mountpoint}}->{$metric->{metric}->{__name__}} = ${$metric->{value}}[1];
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

=item B<--node>

Filter on a specific node (Must be a regexp, Default: '.*')

=item B<--storage>

Filter on a specific storage (Must be a regexp, Default: '.*')

=item B<--exclude-storage-type>

Exclude storage types (Must be a regexp, Default: 'rootfs|tmpfs')

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple, metric can be 'free', 'size')

Example : --metric-overload='metric,^my_metric_name$'

=back

=cut
