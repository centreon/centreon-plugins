#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::kubernetes::mode::nodeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

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
            message_multiple => 'All nodes usage are ok', skipped_code => { -11 => 1 } },
    ];

    $self->{maps_counters}->{nodes} = [
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
        "filter-name:s" => { name => 'filter_name' },
        "units:s"       => { name => 'units', default => '%' },        
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};

    my $nodes = $options{custom}->kubernetes_list_nodes();
    
    foreach my $node (@{$nodes->{items}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $node->{metadata}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $node->{metadata}->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{nodes}->{$node->{metadata}->{name}} = {
            display => $node->{metadata}->{name},
            capacity => $node->{status}->{capacity}->{pods},
            allocatable => $node->{status}->{allocatable}->{pods},
        }            
    }
    
    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No nodes found.");
        $self->{output}->option_exit();
    }
    
    my $pods = $options{custom}->kubernetes_list_pods();

    foreach my $pod (@{$pods->{items}}) {
        next if (defined($pod->{spec}->{nodeName}) && !defined($self->{nodes}->{$pod->{spec}->{nodeName}}));
        $self->{nodes}->{$pod->{spec}->{nodeName}}->{allocated}++;
    }
}

1;

__END__

=head1 MODE

Check node usage.

=over 8

=item B<--filter-name>

Filter node name (can be a regexp).

=item B<--warning-allocated-pods>

Threshold warning for pods allocation.

=item B<--critical-allocated-pods>

Threshold critical for pods allocation.

=item B<--units>

Units of thresholds (Default: '%') (Can be '%' or absolute).

=back

=cut
