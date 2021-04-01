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

package cloud::prometheus::direct::kubernetes::mode::nodestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Status is '%s', New Pods Schedulable : %s",
        $self->{result_values}->{status},
        $self->{result_values}->{schedulable});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{schedulable} = ($options{new_datas}->{$self->{instance} . '_unschedulable'} == 1) ? "false" : "true";

    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'allocated_pods';
    my $value_perf = $self->{result_values}->{allocated};
    
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{allocatable};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label,
        nlabel => 'pods.allocated.count',
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{allocatable},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{allocated};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_allocated};
    }
    $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                  { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]
    );
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Pods Capacity: %s, Allocatable: %s, Allocated: %s (%.2f%%)",
        $self->{result_values}->{capacity},
        $self->{result_values}->{allocatable},
        $self->{result_values}->{allocated},
        $self->{result_values}->{prct_allocated});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{capacity} = $options{new_datas}->{$self->{instance} . '_capacity'};    
    $self->{result_values}->{allocatable} = $options{new_datas}->{$self->{instance} . '_allocatable'};
    $self->{result_values}->{allocated} = $options{new_datas}->{$self->{instance} . '_allocated'};
    $self->{result_values}->{prct_allocated} = ($self->{result_values}->{allocatable} > 0) ? $self->{result_values}->{allocated} * 100 / $self->{result_values}->{allocatable} : 0;
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output',
          message_multiple => 'All nodes status are ok', message_separator => ' - ', skipped_code => { -11 => 1 } },
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'status', set => {
                key_values => [ { name => 'status' }, { name => 'unschedulable' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'allocated-pods', set => {
                key_values => [ { name => 'capacity' }, { name => 'allocatable' }, { name => 'allocated' },
                    { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "node:s"                => { name => 'node', default => 'node=~".*"' },
        "warning-status:s"      => { name => 'warning_status' },
        "critical-status:s"     => { name => 'critical_status', default => '%{status} !~ /Ready/ || %{schedulable} =~ /false/' },
        "extra-filter:s@"       => { name => 'extra_filter' },
        "metric-overload:s@"    => { name => 'metric_overload' },
        "units:s"               => { name => 'units', default => ''  },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{metrics} = {
        'status' => '^kube_node_status_condition$',
        'unschedulable' => '^kube_node_spec_unschedulable$',
        'capacity' => '^kube_node_status_capacity_pods$',
        'allocatable' => '^kube_node_status_allocatable_pods$',
        'allocated' => '^kubelet_running_pod_count$',
    };
    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }

    $self->{labels} = {};
    foreach my $label (('node')) {
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

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};
    
    my $results = $options{custom}->query(
        queries => [
            'label_replace({__name__=~"' . $self->{metrics}->{status} . '",' .
                $self->{option_results}->{node} . ',' .
                'status="true"' .
                $self->{extra_filter} . '}, "__name__", "status", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{unschedulable} . '",' .
                $self->{option_results}->{node} .
                $self->{extra_filter} . '}, "__name__", "unschedulable", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{capacity} . '",' .
                $self->{option_results}->{node} .
                $self->{extra_filter} . '}, "__name__", "capacity", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{allocatable} . '",' .
                $self->{option_results}->{node} .
                $self->{extra_filter} . '}, "__name__", "allocatable", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{allocated} . '",' .
                $self->{option_results}->{node} .
                $self->{extra_filter} . '}, "__name__", "allocated", "", "")'
        ]
    );

    foreach my $result (@{$results}) {
        $self->{nodes}->{$result->{metric}->{$self->{labels}->{node}}}->{display} = $result->{metric}->{$self->{labels}->{node}};
        $self->{nodes}->{$result->{metric}->{$self->{labels}->{node}}}->{$result->{metric}->{__name__}} = ${$result->{value}}[1];
        $self->{nodes}->{$result->{metric}->{$self->{labels}->{node}}}->{$result->{metric}->{__name__}} = $result->{metric}->{condition} if ($result->{metric}->{__name__} =~ /status/);
    }
    
    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No nodes found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check node status.

=over 8

=item B<--node>

Filter on a specific node (Must be a PromQL filter, Default: 'node=~".*"')

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{display}, %{status}, %{schedulable}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /Ready/ || %{schedulable} != /false/').
Can used special variables like: %{display}, %{status}, %{schedulable}

=item B<--warning-allocated-pods>

Threshold warning for pods allocation.

=item B<--critical-allocated-pods>

Threshold critical for pods allocation.

=item B<--units>

Units of thresholds (Default: '') (Can be '%').

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple)

Example : --metric-overload='metric,^my_metric_name$'

Default :

    - status: ^kube_node_status_condition$
    - unschedulable: ^kube_node_spec_unschedulable$
    - capacity: ^kube_node_status_capacity_pods$
    - allocatable: ^kube_node_status_allocatable_pods$
    - allocated: ^kubelet_running_pod_count$

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=back

=cut
