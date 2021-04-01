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

package cloud::prometheus::direct::kubernetes::mode::listnodes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "node:s"                      => { name => 'node', default => 'node=~".*"' },
                                  "os-image:s"                  => { name => 'os_image', default => 'os_image=~".*"' },
                                  "kubelet-version:s"           => { name => 'kubelet_version', default => 'kubelet_version=~".*"' },
                                  "kubeproxy-version:s"         => { name => 'kubeproxy_version', default => 'kubeproxy_version=~".*"' },
                                  "kernel-version:s"            => { name => 'kernel_version', default => 'kernel_version=~".*"' },
                                  "container-runtime-version:s" => { name => 'container_runtime_version', default => 'container_runtime_version=~".*"' },
                                  "extra-filter:s@"             => { name => 'extra_filter' },
                                  "metric-overload:s@"          => { name => 'metric_overload' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{metrics} = {
        'info' => '^kube_node_info$',
    };
    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }

    $self->{labels} = {};
    foreach my $label (('node', 'os_image', 'kubelet_version', 'kubeproxy_version', 'kernel_version', 'container_runtime_version')) {
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

    $self->{nodes} = $options{custom}->query(queries => [ '{__name__=~"' . $self->{metrics}->{info} . '",' .
                                                            $self->{option_results}->{node} . ',' .
                                                            $self->{option_results}->{os_image} . ',' .
                                                            $self->{option_results}->{kubelet_version} . ',' .
                                                            $self->{option_results}->{kubeproxy_version} . ',' .
                                                            $self->{option_results}->{kernel_version} . ',' .
                                                            $self->{option_results}->{container_runtime_version} .
                                                            $self->{extra_filter} . '}' ]);
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $node (@{$self->{nodes}}) {
        $self->{output}->output_add(long_msg => sprintf("[node = %s][os_image = %s][kubelet_version = %s][kubeproxy_version = %s]" .
            "[kernel_version = %s][container_runtime_version = %s]",
            $node->{metric}->{$self->{labels}->{node}}, $node->{metric}->{$self->{labels}->{os_image}},
            $node->{metric}->{$self->{labels}->{kubelet_version}}, $node->{metric}->{$self->{labels}->{kubeproxy_version}},
            $node->{metric}->{$self->{labels}->{kernel_version}}, $node->{metric}->{$self->{labels}->{container_runtime_version}}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List nodes:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['node', 'os_image', 'kubelet_version', 'kubeproxy_version',
        'kernel_version', 'container_runtime_version']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $node (@{$self->{nodes}}) {
        $self->{output}->add_disco_entry(
            node => $node->{metric}->{$self->{labels}->{node}},
            os_image => $node->{metric}->{$self->{labels}->{os_image}},
            kubelet_version => $node->{metric}->{$self->{labels}->{kubelet_version}},
            kubeproxy_version => $node->{metric}->{$self->{labels}->{kubeproxy_version}},
            kernel_version => $node->{metric}->{$self->{labels}->{kernel_version}},
            container_runtime_version => $node->{metric}->{$self->{labels}->{container_runtime_version}},
        );
    }
}

1;

__END__

=head1 MODE

List nodes.

=over 8

=item B<--node>

Filter on a specific node (Must be a PromQL filter, Default: 'node=~".*"')

=item B<--os-image>

Filter on a specific os image (Must be a PromQL filter, Default: 'os_image=~".*"')

=item B<--kubelet-version>

Filter on a specific kubelet version (Must be a PromQL filter, Default: 'kubelet_version=~".*"')

=item B<--kubeproxy-version>

Filter on a specific kubeproxy version (Must be a PromQL filter, Default: 'kubeproxy_version=~".*"')

=item B<--kernel-version>

Filter on a specific kernel version (Must be a PromQL filter, Default: 'kernel_version=~".*"')

=item B<--container-runtime-version>

Filter on a specific container runtime version (Must be a PromQL filter, Default: 'container_runtime_version=~".*"')

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple, metric can be 'info')

Example : --metric-overload='metric,^my_metric_name$'

=back

=cut
