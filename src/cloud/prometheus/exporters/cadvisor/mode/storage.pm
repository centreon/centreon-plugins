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

package cloud::prometheus::exporters::cadvisor::mode::storage;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw(:counters :values);

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
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{perf} : undef,
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

    my ($total_limit_value, $total_limit_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Usage Limit: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_limit_value . " " . $total_limit_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $self->{instance};
    $self->{result_values}->{perf} = $options{new_datas}->{$self->{instance} . '_perf'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_limit'};    
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
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
        { name => 'containers', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_containers_output', cb_long_output => 'long_output',
          message_multiple => 'All containers storages usage are ok', indent_long_output => '    ',
            group => [
                { name => 'storage', display_long => 1, cb_prefix_output => 'prefix_storage_output',
                  message_multiple => 'All storages usage are ok', type => COUNTER_MULTIPLE_SUBINSTANCE, skipped_code => { NO_VALUE() => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{storage} = [
        { label => 'usage', set => {
                key_values => [ { name => 'used' }, { name => 'limit' }, { name => 'perf' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_containers_output {
    my ($self, %options) = @_;

    my ($pod, $container) = ($options{instance_value}->{pod}, $options{instance_value}->{container});
    return "Pod '" . $pod . "' " if ($container eq '');
    return "Container '" . $container . "' " if ($pod eq '');
    return "Container '" . $container . "' [pod: " . $pod . "] ";
}

sub long_output {
    my ($self, %options) = @_;

    my ($pod, $container) = ($options{instance_value}->{pod}, $options{instance_value}->{container});
    return "Checking pod '" . $pod . "'" if ($container eq '');
    return "Checking container '" . $container . "'" if ($pod eq '');
    return "Checking container '" . $container . "' [pod: " . $pod . "]";
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
        "container:s"           => { name => 'container', default => 'container!~"|.*POD.*"' },
        "pod:s"                 => { name => 'pod', default => 'pod=~".*"' },
        "namespace:s"           => { name => 'namespace', default => 'namespace=~".*"' },
        "device:s"              => { name => 'device', default => 'device=~".*"' },
        "extra-filter:s@"       => { name => 'extra_filter' },
        "units:s"               => { name => 'units', default => '%' },
        "free"                  => { name => 'free' },
        "metric-overload:s@"    => { name => 'metric_overload' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{metrics} = {
        'used' => "^container_fs_usage_bytes.*",
        'limit' => "^container_fs_limit_bytes.*",
    };
    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }

    $self->{labels} = {};
    foreach my $label (('container', 'pod', 'namespace', 'device')) {
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

    $self->{containers} = {};

    my $results = $options{custom}->query(
        queries => [
            'label_replace({__name__=~"' . $self->{metrics}->{used} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} . ',' . $self->{option_results}->{namespace} . ',' .
                $self->{option_results}->{device} .
                $self->{extra_filter} . '}, "__name__", "used", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{limit} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} . ',' . $self->{option_results}->{namespace} . ',' .
                $self->{option_results}->{device} .
                $self->{extra_filter} . '}, "__name__", "limit", "", "")'
        ]
    );

    foreach my $result (@{$results}) {
        my $pod = $result->{metric}->{$self->{labels}->{pod}} // '';
        my $container = $result->{metric}->{$self->{labels}->{container}} // '';
        next if ($pod eq '' && $container eq '');
        # without container label, keep the pod cgroup: the pause container has a name and would overwrite it
        next if ($container eq '' && defined($result->{metric}->{name}));
        my $namespace = $result->{metric}->{$self->{labels}->{namespace}} // '';
        my $name = join("_", $namespace, $pod, $container);

        $self->{containers}->{$name}->{display} = $name;
        $self->{containers}->{$name}->{container} = $container;
        $self->{containers}->{$name}->{pod} = $pod;

        my $device = $result->{metric}->{$self->{labels}->{device}};
        my $storage = $self->{containers}->{$name}->{storage}->{$device} //= {
            display => $device,
            perf    => [ grep { $_ ne '' } ($pod, $container, $device) ]
        };
        $storage->{$result->{metric}->{__name__}} = ${$result->{value}}[1];
    }

    if (scalar(keys %{$self->{containers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No containers found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check containers storages usage.

The cAdvisor built in the kubelet (C</metrics/cadvisor>) does not export the disk usage of
C<containerd> containers: this mode needs a standalone cAdvisor.

Each series matching the filters is reported as:

=over 4

=item * a pod, when it has no container label (pod cgroup). The pause container of the pod is ignored.
These series are excluded by the default C<--container> filter.

=item * a container of a pod, when it has both labels.

=item * a container running outside Kubernetes, when it has no pod label.

=back

=over 8

=item B<--container>

Filter on a specific container (must be a PromQL filter, Default: 'container!~"|.*POD.*"')

=item B<--pod>

Filter on a specific pod (must be a PromQL filter, Default: 'pod=~".*"')

The label filtered is the first word of the C<--container> and C<--pod> filters.
The kubelet cAdvisor metrics label names depend on the platform version:

=over 4

=item * Kubernetes < 1.14: C<container_name> and C<pod_name> only.

=item * Kubernetes 1.14 and 1.15: both C<container_name>/C<pod_name> and C<container>/C<pod>.

=item * Kubernetes >= 1.16: C<container> and C<pod> only.

=item * OpenShift: C<container_name> and C<pod_name> only up to 4.1 (Kubernetes 1.13),
both label sets in 4.2 (Kubernetes 1.14), C<container> and C<pod> only from 4.3 (Kubernetes 1.16).

=item * Rancher: depends on the Kubernetes version of the managed cluster. Kubernetes 1.16 is
available from Rancher 2.3.0 (experimental), generally available in 2.3.2 and the default in 2.3.3.

=back

On older platforms, use for example: --container='container_name!~"|.*POD.*"' --pod='pod_name=~".*"'

=item B<--namespace>

Filter on a specific namespace (must be a PromQL filter, Default: 'namespace=~".*"').
Two pods with the same name in different namespaces are reported separately, but with the
same output and performance data names: filter on the namespace to tell them apart.

=item B<--device>

Filter on a specific device (must be a PromQL filter, Default: 'device=~".*"')

=item B<--units>

Units of thresholds (default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--warning-usage>

Warning threshold.

=item B<--critical-usage>

Critical threshold.

=item B<--extra-filter>

Add a PromQL filter (can be defined multiple times)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (can be defined multiple times)

Example : --metric-overload='metric,^my_metric_name$'

Default :

    - used: ^container_fs_usage_bytes.*
    - limit: ^container_fs_limit_bytes.*

=back

=cut
