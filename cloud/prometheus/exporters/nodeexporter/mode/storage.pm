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

package cloud::prometheus::exporters::nodeexporter::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};

    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        nlabel => 'storage.space.usage.bytes', 
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
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
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                              { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
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

    $self->{result_values}->{label} = $self->{instance};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
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
        { name => 'nodes', type => 3, cb_prefix_output => 'prefix_node_output', cb_long_output => 'node_long_output',
          message_multiple => 'All nodes storages usage are ok', indent_long_output => '    ',
            group => [
                { name => 'storage', display_long => 1, cb_prefix_output => 'prefix_storage_output',
                  message_multiple => 'All storages usage are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{storage} = [
        { label => 'usage', set => {
                key_values => [ { name => 'free' }, { name => 'size' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                label_extra_instance => 1, instance_use => 'display'
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

sub prefix_storage_output {
    my ($self, %options) = @_;

    return "Storage '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "instance:s"              => { name => 'instance', default => 'instance=~".*"' },
        "mountpoint:s"            => { name => 'mountpoint', default => 'mountpoint=~".*"' },
        "fstype:s"                => { name => 'fstype', default => 'fstype!~"linuxfs|rootfs|tmpfs"' },
        "units:s"                 => { name => 'units', default => '%' },
        "free"                    => { name => 'free' },
        "extra-filter:s@"         => { name => 'extra_filter' },
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

    $self->{labels} = {};
    foreach my $label (('instance', 'mountpoint', 'fstype')) {
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
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};

    my $results = $options{custom}->query(
        queries => [
            'label_replace({__name__=~"' . $self->{metrics}->{free} . '",' .
                $self->{option_results}->{instance} . ',' .
                $self->{option_results}->{mountpoint} . ',' .
                $self->{option_results}->{fstype} .
                $self->{extra_filter} . '}, "__name__", "free", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{size} . '",' .
                $self->{option_results}->{instance} . ',' .
                $self->{option_results}->{mountpoint} . ',' .
                $self->{option_results}->{fstype} .
                $self->{extra_filter} . '}, "__name__", "size", "", "")'
        ]
    );

    foreach my $result (@{$results}) {
        $self->{nodes}->{$result->{metric}->{$self->{labels}->{instance}}}->{display} = $result->{metric}->{$self->{labels}->{instance}};
        $self->{nodes}->{$result->{metric}->{$self->{labels}->{instance}}}->{storage}->{$result->{metric}->{mountpoint}}->{display} = $result->{metric}->{$self->{labels}->{mountpoint}};
        $self->{nodes}->{$result->{metric}->{$self->{labels}->{instance}}}->{storage}->{$result->{metric}->{mountpoint}}->{$result->{metric}->{__name__}} = ${$result->{value}}[1];
    }

    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No nodes found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check storages usage.

=over 8

=item B<--instance>

Filter on a specific instance (Must be a PromQL filter, Default: 'instance=~".*"')

=item B<--mountpoint>

Filter on a specific mountpoint (Must be a PromQL filter, Default: 'mountpoint=~".*"')

=item B<--fstype>

Filter on a specific fstype (Must be a PromQL filter, Default: 'fstype!~"linuxfs|rootfs|tmpfs"')

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

Overload default metrics name (Can be multiple)

Example : --metric-overload='metric,^my_metric_name$'

Default :

    - free: ^node_filesystem_free.*
    - size: ^node_filesystem_size.*

=back

=cut
