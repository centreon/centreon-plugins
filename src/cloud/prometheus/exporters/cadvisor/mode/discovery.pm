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

package cloud::prometheus::exporters::cadvisor::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;
use centreon::plugins::misc qw(is_empty);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    my %label_name = (
        not_empty     => 1,
        regexp_match  => '^[a-zA-Z_][a-zA-Z0-9_]*$',
        error_message => 'Need to specify --%{option} option as a Prometheus label name.'
    );
    $options{options}->add_options(arguments => {
        'container-label:s'  => { name => 'container_label', default => 'container', %label_name },
        'pod-label:s'        => { name => 'pod_label', default => 'pod', %label_name },
        'namespace-label:s'  => { name => 'namespace_label', default => 'namespace', %label_name },
        'name-label:s'       => { name => 'name_label', default => 'name', %label_name },
        'extra-filter:s@'    => { name => 'extra_filter' },
        'metric-last-seen:s' => { name => 'metric_last_seen', default => '^container_last_seen$', not_empty => 1 },
        'prettify'           => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{labels} = { map { $_ => $self->{option_results}->{$_ . '_label'} } ('container', 'pod', 'namespace', 'name') };

    $self->{extra_filter} = '';
    foreach my $filter (@{$self->{option_results}->{extra_filter}}) {
        $self->{extra_filter} .= ',' . $filter;
    }
}

# A container can have several series (restarts, image updates): keep the image of the most recent one
sub update_image {
    my ($self, %options) = @_;

    my $last_seen = $options{result}->{value}->[1] // 0;
    return if (defined($options{item}->{_last_seen}) && $options{item}->{_last_seen} >= $last_seen);

    $options{item}->{_last_seen} = $last_seen;
    $options{item}->{container_image} = $options{result}->{metric}->{image} // '';
}

sub manage_selection {
    my ($self, %options) = @_;

    my $disco_stats = { start_time => time() };

    my $results = $options{custom}->query(
        queries => [
            '{__name__=~"' . $self->{option_results}->{metric_last_seen} . '"' .
            $self->{extra_filter} . '}'
        ]
    );

    my ($pods, $containers) = ({}, {});
    foreach my $result (@{$results}) {
        my $metric = $result->{metric};
        my $pod = $metric->{$self->{labels}->{pod}};
        my $target_labels = {
            node     => $metric->{node} // '',
            instance => $metric->{instance} // '',
            job      => $metric->{job} // ''
        };

        # Series without pod: standalone container (docker, podman...) identified by its name.
        # Series without pod and name are the root cgroup and system slices.
        if (is_empty($pod)) {
            my $name = $metric->{$self->{labels}->{name}};
            next if (is_empty($name));

            # the same container name can exist on several Docker hosts
            my $id = is_empty($target_labels->{instance}) ? $name : $target_labels->{instance} . '/' . $name;
            $containers->{$id} //= {
                %$target_labels,
                type                 => 'container',
                source               => 'standalone',
                id                   => $id,
                name                 => $name,
                container_name       => $name,
                container_image      => $metric->{image} // '',
                kubernetes_pod       => '',
                kubernetes_namespace => ''
            };
            $self->update_image(item => $containers->{$id}, result => $result);
            next;
        }

        my $namespace = $metric->{$self->{labels}->{namespace}} // '';
        my $container = $metric->{$self->{labels}->{container}};
        my $pod_labels = {
            %$target_labels,
            source               => 'kubernetes',
            kubernetes_pod       => $pod,
            kubernetes_namespace => $namespace
        };

        # Every series of a pod (containers, pause container, pod cgroup) describes the pod itself
        my $pod_id = $namespace . '/' . $pod;
        $pods->{$pod_id} //= {
            %$pod_labels,
            type            => 'pod',
            id              => $pod_id,
            name            => $pod,
            container_name  => '',
            container_image => ''
        };

        # Skip the pod cgroup (no container label) and the pause container
        next if (is_empty($container) || $container eq 'POD');

        my $container_id = $pod_id . '/' . $container;
        $containers->{$container_id} //= {
            %$pod_labels,
            type            => 'container',
            id              => $container_id,
            name            => $container,
            container_name  => $container,
            container_image => $metric->{image} // ''
        };
        $self->update_image(item => $containers->{$container_id}, result => $result);
    }

    delete $_->{_last_seen} foreach (values %$containers);
    my @disco_data = (
        map({ $pods->{$_} } sort(keys %$pods)),
        map({ $containers->{$_} } sort(keys %$containers))
    );

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = int(scalar(@disco_data));
    $disco_stats->{results} = \@disco_data;

    return $disco_stats;
}

sub run {
    my ($self, %options) = @_;

    my $encoded_data;

    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->canonical->pretty->encode($self->manage_selection(%options));
        } else {
            $encoded_data = JSON::XS->new->utf8->canonical->encode($self->manage_selection(%options));
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Resources discovery (pods and containers).

Each discovered item has the following properties:

=over 4

=item * C<type>: C<pod> or C<container>.

=item * C<source>: C<kubernetes>, or C<standalone> for a container
running outside Kubernetes (identified by the C<--name-label> label).

=item * C<id>: unique identifier (C<namespace/pod> for a pod,
C<namespace/pod/container> for a Kubernetes container, C<instance/name> for a
standalone container).

=item * C<name>: pod or container name.

=item * C<container_name>, C<container_image>: container information (empty for a pod).

=item * C<kubernetes_pod>, C<kubernetes_namespace>: Kubernetes information
(empty for a standalone container).

=item * C<node>: value of the C<node> label, empty if the label does not exist.
cAdvisor does not set it: it is added on the Prometheus side, usually by the
relabeling of the kubelet scrape job or by a static label in the scrape configuration. It can
therefore also be set on standalone containers.

=item * C<job>, C<instance>: Prometheus scrape target the series comes from.

=back

Pods are only discovered from Kubernetes series.

Kubernetes pause containers (container 'POD' or empty) are not returned as
containers. Series without pod and name labels (root cgroup, system slices)
are ignored.

=over 8

=item B<--container-label>

Name of the Prometheus label holding the container name (default: 'container').

=item B<--pod-label>

Name of the Prometheus label holding the pod name (default: 'pod').

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

On older platforms, use: --container-label='container_name' --pod-label='pod_name'

With a standalone cAdvisor deployed in Kubernetes (DaemonSet), the series do not have the
pod and container labels set by the kubelet, only the labels of the container runtime
(exported by cAdvisor with its default C<--store_container_labels> option). Use:
--container-label='container_label_io_kubernetes_container_name'
--pod-label='container_label_io_kubernetes_pod_name'
--namespace-label='container_label_io_kubernetes_pod_namespace'

=item B<--namespace-label>

Name of the Prometheus label holding the namespace (default: 'namespace').

=item B<--name-label>

Name of the Prometheus label holding the name of containers running outside
Kubernetes (default: 'name').

=item B<--extra-filter>

Add a PromQL filter (can be defined multiple times).
Series without the filtered label do not match: filtering on namespace
excludes standalone containers.

Example : --extra-filter='namespace=~"monitoring|default"'

=item B<--metric-last-seen>

Regular expression matching the name of the Prometheus metric used to list
resources (default: '^container_last_seen$').

Example : --metric-last-seen='^k8s_container_last_seen$'

=item B<--prettify>

Prettify JSON output.

=back

=cut
