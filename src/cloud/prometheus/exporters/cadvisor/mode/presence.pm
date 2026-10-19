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

package cloud::prometheus::exporters::cadvisor::mode::presence;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_empty);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL },
        { name => 'containers', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_containers_output',
          message_multiple => 'All containers are present', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'containers-detected', nlabel => 'containers.detected.count', critical_default => '1:', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'Containers detected: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{containers} = [
        { label => 'last-seen', nlabel => 'container.last_seen.seconds', set => {
                key_values => [ { name => 'last_seen' }, { name => 'display' }, { name => 'perf' } ],
                output_template => 'last seen %.2fs ago',
                perfdatas => [
                    { template => '%.2f', unit => 's', min => 0, label_extra_instance => 1, instance_use => 'perf' }
                ]
            }
        }
    ];
}

sub prefix_containers_output {
    my ($self, %options) = @_;

    return $options{instance_value}->{display} . ' ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'container:s'        => { name => 'container', default => 'container!~".*POD.*"' },
        'pod:s'              => { name => 'pod', default => 'pod=~".*"' },
        'name-label:s'       => { name => 'name_label', default => 'name' },
        'extra-filter:s@'    => { name => 'extra_filter' },
        'metric-last-seen:s' => { name => 'metric_last_seen', default => '^container_last_seen$', not_empty => 1 }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{labels} = {};
    foreach my $label (('container', 'pod')) {
        if ($self->{option_results}->{$label} !~ /^(\w+)[!~=]+\".*\"$/) {
            $self->{output}->add_option_msg(short_msg => "Need to specify --" . $label . " option as a PromQL filter.");
            $self->{output}->option_exit();
        }
        $self->{labels}->{$label} = $1;
    }

    if (is_empty($self->{option_results}->{name_label}) || $self->{option_results}->{name_label} !~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --name-label option as a Prometheus label name.");
        $self->{output}->option_exit();
    }
    $self->{labels}->{name} = $self->{option_results}->{name_label};

    $self->{extra_filter} = '';
    foreach my $filter (@{$self->{option_results}->{extra_filter}}) {
        $self->{extra_filter} .= ',' . $filter;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->query(
        queries => [
            '{__name__=~"' . $self->{option_results}->{metric_last_seen} . '",' .
                $self->{option_results}->{container} . ',' .
                $self->{option_results}->{pod} .
                $self->{extra_filter} . '}'
        ]
    );

    $self->{containers} = {};
    foreach my $result (@{$results}) {
        my $pod = $result->{metric}->{$self->{labels}->{pod}} // '';
        my $container = $result->{metric}->{$self->{labels}->{container}} // '';
        if ($pod eq '' && $container eq '') {
            $container = $result->{metric}->{$self->{labels}->{name}} // '';
            next if ($container eq '');
        }

        my ($evaluation_time, $last_seen_time) = @{$result->{value}};
        my $last_seen = $evaluation_time - $last_seen_time;
        $last_seen = 0 if ($last_seen < 0);

        my $id = join('~', grep { $_ ne '' } ($pod, $container));
        next if (defined($self->{containers}->{$id}) && $self->{containers}->{$id}->{last_seen} <= $last_seen);

        my $display = "Container '" . $container . "' [pod: " . $pod . "]";
        $display = "Pod '" . $pod . "'" if ($container eq '');
        $display = "Container '" . $container . "'" if ($pod eq '');

        $self->{containers}->{$id} = {
            display   => $display,
            perf      => $id,
            last_seen => $last_seen
        };
    }

    $self->{global} = { detected => scalar(keys %{$self->{containers}}) };
}

1;

__END__

=head1 MODE

Check that pods and containers are present in cAdvisor metrics and when they were last seen.

Each C<container_last_seen> series matching the filters is detected as:

=over 4

=item * a pod, when it has a pod label but no container label (pod cgroup).

=item * a container of a pod, when it has both labels.

=item * a container running outside Kubernetes, when it has neither: it is then named by
the C<--name-label> label.

=back

The series without any name (root cgroup, system slices) are ignored. When several series
match the same pod or container (for example the pod cgroup and the pause container), the
most recent one is used.

Examples:

=over 4

=item * a pod: --pod='pod="my-pod"' --container='container=""'

=item * a container of a pod: --pod='pod="my-pod"' --container='container="my-container"'

=item * a container outside Kubernetes: --container='name="my-container"'

=back

By default, the check is C<CRITICAL> when nothing is detected. It can be used as a host
check for a host modeling a pod or a container.

=over 8

=item B<--container>

Filter on a specific container (must be a PromQL filter, Default: 'container!~".*POD.*"')

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

On older platforms, use for example: --container='container_name!~".*POD.*"' --pod='pod_name=~".*"'

A container running outside Kubernetes has no pod label: filter it on its C<name>
label, for example: --container='name="haproxy"'
Its output and performance data only show the container name.

=item B<--name-label>

Name of the Prometheus label holding the name of containers running outside
Kubernetes, used when a series has neither pod nor container label (default: 'name').

=item B<--extra-filter>

Add a PromQL filter (can be defined multiple times)

Example : --extra-filter='namespace="monitoring"'

=item B<--metric-last-seen>

Regular expression matching the name of the Prometheus metric holding the last time
a container was seen (default: '^container_last_seen$').

=item B<--warning-containers-detected>

Threshold on the number of containers detected.

=item B<--critical-containers-detected>

Threshold on the number of containers detected (default: '1:').

=item B<--warning-last-seen>

Threshold on the number of seconds since the container was last seen.
The value is computed at the Prometheus query time: in normal conditions, it stays
below the cAdvisor housekeeping interval plus the Prometheus scrape interval.

=item B<--critical-last-seen>

Threshold on the number of seconds since the container was last seen.

=back

=cut
