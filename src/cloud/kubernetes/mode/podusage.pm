#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::kubernetes::mode::podusage;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw/:values :counters/;
use centreon::plugins::misc qw/convert_bytes_ng/;
use centreon::common::kubernetes::misc qw/to_millicores/;

use strict;
use warnings;

sub custom_usage_prct_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};

    my $resource = $options{extra_options}->{resource};
    my $usage = $options{new_datas}->{$self->{instance} . '_' . $resource . '_usage'};
    my $requests = $options{new_datas}->{$self->{instance} . '_' . $resource . '_requests'};

    return NO_VALUE if !defined($requests) || $requests <= 0;

    $self->{result_values}->{usage_prct} = $usage * 100 / $requests;
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'pods', type => COUNTER_TYPE_INSTANCE, prefix_output => "Pod '%{display}' ",
            message_multiple => 'All pods usage are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{pods} = [
        { label => 'pod-cpu-usage', nlabel => 'pod.cpu.usage.millicores', set => {
                key_values => [ { name => 'cpu_usage' }, { name => 'display' } ],
                output_template => 'CPU usage: %{cpu_usage} millicores',
                perfdatas => [
                    { value => 'cpu_usage', template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'pod-cpu-percentage', nlabel => 'pod.cpu.usage.percentage', set => {
                key_values => [ { name => 'cpu_usage' }, { name => 'cpu_requests' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_prct_calc'),
                closure_custom_calc_extra_options => { resource => 'cpu' },
                output_template => 'CPU usage: %{usage_prct|%.2f}%% of requests',
                threshold_use => 'usage_prct',
                perfdatas => [
                    { value => 'usage_prct', template => '%.2f', unit => '%', min => 0, max => 100,
                      label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'pod-memory-usage', nlabel => 'pod.memory.usage.bytes', set => {
                key_values => [ { name => 'memory_usage' }, { name => 'display' } ],
                output_template => 'Memory usage: %{memory_usage|storage}',
                perfdatas => [
                    { value => 'memory_usage', template => '%d', unit => 'B', min => 0,
                      label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'pod-memory-percentage', nlabel => 'pod.memory.usage.percentage', set => {
                key_values => [ { name => 'memory_usage' }, { name => 'memory_requests' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_prct_calc'),
                closure_custom_calc_extra_options => { resource => 'memory' },
                output_template => 'Memory usage: %{usage_prct|%.2f}%% of requests',
                threshold_use => 'usage_prct',
                perfdatas => [
                    { value => 'usage_prct', template => '%.2f', unit => '%', min => 0, max => 100,
                      label_extra_instance => 1, instance_use => 'display' }
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
        'filter-name:s'           => { name => 'filter_name' },
        'filter-namespace:s'      => { name => 'filter_namespace' },
        'filter-container-name:s' => { name => 'filter_container_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{pods} = {};

    my %pod_specs;
    my $specs = $options{custom}->kubernetes_list_pods();
    foreach my $pod (@{$specs}) {
        next if !defined($pod->{metadata}->{name}) || !defined($pod->{metadata}->{namespace});

        my $key = $pod->{metadata}->{namespace} . '/' . $pod->{metadata}->{name};
        next if defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $pod->{metadata}->{name} !~ /$self->{option_results}->{filter_name}/;
        next if defined($self->{option_results}->{filter_namespace}) && $self->{option_results}->{filter_namespace} ne ''
            && $pod->{metadata}->{namespace} !~ /$self->{option_results}->{filter_namespace}/;

        if (!defined($pod->{status}->{phase}) || lc($pod->{status}->{phase}) eq 'pending') {
            $self->{output}->output_add(long_msg => "skipping pod '" . $key . "': phase is pending or unknown", debug => 1);
            next;
        }

        my ($cpu_requests, $memory_requests) = (0, 0);
        foreach my $container (@{$pod->{spec}->{containers}}) {
            next if defined($self->{option_results}->{filter_container_name}) && $self->{option_results}->{filter_container_name} ne ''
                && $container->{name} !~ /$self->{option_results}->{filter_container_name}/;

            $cpu_requests += to_millicores(value => $container->{resources}->{requests}->{cpu})
                if defined($container->{resources}->{requests}->{cpu});
            $memory_requests += convert_bytes_ng(value => $container->{resources}->{requests}->{memory})
                if defined($container->{resources}->{requests}->{memory});
        }

        $pod_specs{$key} = { cpu_requests => $cpu_requests, memory_requests => $memory_requests };
    }

    $self->{output}->option_exit(short_msg => 'No pod found matching filters')
        unless keys %pod_specs;

    my $metrics = $options{custom}->kubernetes_list_pod_metrics();
    foreach my $pod_metric (@{$metrics}) {
        next if !defined($pod_metric->{metadata}->{name}) || !defined($pod_metric->{metadata}->{namespace});

        my $key = $pod_metric->{metadata}->{namespace} . '/' . $pod_metric->{metadata}->{name};
        next unless defined($pod_specs{$key});

        my ($cpu_usage, $memory_usage) = (0, 0);
        foreach my $container (@{$pod_metric->{containers}}) {
            next if defined($self->{option_results}->{filter_container_name}) && $self->{option_results}->{filter_container_name} ne ''
                && $container->{name} !~ /$self->{option_results}->{filter_container_name}/;

            $cpu_usage += to_millicores(value => $container->{usage}->{cpu}) if defined($container->{usage}->{cpu});
            $memory_usage += convert_bytes_ng(value => $container->{usage}->{memory}) if defined($container->{usage}->{memory});
        }

        $self->{pods}->{$key} = {
            display => $key,
            cpu_usage => $cpu_usage,
            cpu_requests => $pod_specs{$key}->{cpu_requests},
            memory_usage => $memory_usage,
            memory_requests => $pod_specs{$key}->{memory_requests}
        };
    }

    $self->{output}->option_exit(short_msg => 'No pod found matching filters')
        unless keys %{$self->{pods}};
}

1;

__END__

=head1 MODE

Check Kubernetes pod CPU and memory usage (from the metrics.k8s.io API), against resource requests.

Requires metrics-server to be installed and reachable in the cluster.

=over 8

=item B<--filter-name>

Filter pod name (can be a regexp).

=item B<--filter-namespace>

Filter namespace (can be a regexp).

=item B<--filter-container-name>

Filter container name (can be a regexp). Only matching containers are summed into the pod usage.

=item B<--warning-pod-cpu-usage>

Threshold in millicores.

=item B<--critical-pod-cpu-usage>

Threshold in millicores.

=item B<--warning-pod-cpu-percentage>

Threshold in percentage of CPU requests.

=item B<--critical-pod-cpu-percentage>

Threshold in percentage of CPU requests.

=item B<--warning-pod-memory-usage>

Threshold in bytes.

=item B<--critical-pod-memory-usage>

Threshold in bytes.

=item B<--warning-pod-memory-percentage>

Threshold in percentage of memory requests.

=item B<--critical-pod-memory-percentage>

Threshold in percentage of memory requests.

=back

=cut
