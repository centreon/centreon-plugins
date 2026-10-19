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

package cloud::prometheus::exporters::cadvisor::mode::load;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw(:counters);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'containers', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_containers_output',
          message_multiple => 'All containers load are ok' },
    ];

    $self->{maps_counters}->{containers} = [
        { label => 'load', nlabel => 'container.load.count', set => {
                key_values => [ { name => 'load' }, { name => 'container' }, { name => 'pod' }, { name => 'perf' } ],
                output_template => 'Load: %.2f',
                perfdatas => [
                    { label => 'load', value => 'load', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'perf' },
                ],
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

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "container:s"           => { name => 'container', default => 'container!~"|.*POD.*"' },
        "pod:s"                 => { name => 'pod', default => 'pod=~".*"' },
        "namespace:s"           => { name => 'namespace', default => 'namespace=~".*"' },
        "extra-filter:s@"       => { name => 'extra_filter' },
        "metric-overload:s@"    => { name => 'metric_overload' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{metrics} = {
        'load' => '^container_cpu_load_average_10s$',
    };
    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }

    $self->{labels} = {};
    foreach my $label (('container', 'pod', 'namespace')) {
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

    $self->{prom_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{prom_step} = defined($self->{option_results}->{step}) ? $self->{option_results}->{step} : "1m";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{containers} = {};

    my $results = $options{custom}->query_range(
        queries => [
            'label_replace({__name__=~"' . $self->{metrics}->{load} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} . ',' . $self->{option_results}->{namespace} .
                $self->{extra_filter} . '}, "__name__", "load", "", "")'
        ],
        timeframe => $self->{prom_timeframe},
        step => $self->{prom_step}
    );

    foreach my $result (@{$results}) {
        my $pod = $result->{metric}->{$self->{labels}->{pod}} // '';
        my $container = $result->{metric}->{$self->{labels}->{container}} // '';
        next if ($pod eq '' && $container eq '');
        # without container label, keep the pod cgroup: the pause container has a name and would overwrite it
        next if ($container eq '' && defined($result->{metric}->{name}));
        my $namespace = $result->{metric}->{$self->{labels}->{namespace}} // '';
        my $name = join("_", $namespace, $pod, $container);

        my $average = $options{custom}->compute(aggregation => 'average', values => $result->{values});
        $self->{containers}->{$name}->{container} = $container;
        $self->{containers}->{$name}->{pod} = $pod;
        $self->{containers}->{$name}->{perf} = join('_', grep { $_ ne '' } ($pod, $container));
        $self->{containers}->{$name}->{$result->{metric}->{__name__}} = $average;
    }
    
    if (scalar(keys %{$self->{containers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No containers found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check containers load.

The C<container_cpu_load_average_10s> metric is not exported by the cAdvisor built in the
kubelet (C</metrics/cadvisor>): this mode needs a standalone cAdvisor.

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

=item B<--warning-load>

Warning threshold.

=item B<--critical-load>

Critical threshold.

=item B<--extra-filter>

Add a PromQL filter (can be defined multiple times)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (can be defined multiple times)

Example : --metric-overload='metric,^my_metric_name$'

Default :

    - load: ^container_cpu_load_average_10s$

=back

=cut
