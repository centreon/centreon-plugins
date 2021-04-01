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

package cloud::prometheus::direct::kubernetes::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'container-status'          => 'cloud::prometheus::direct::kubernetes::mode::containerstatus',
        'daemonset-status'          => 'cloud::prometheus::direct::kubernetes::mode::daemonsetstatus',
        'deployment-status'         => 'cloud::prometheus::direct::kubernetes::mode::deploymentstatus',
        'list-containers'           => 'cloud::prometheus::direct::kubernetes::mode::listcontainers',
        'list-daemonsets'           => 'cloud::prometheus::direct::kubernetes::mode::listdaemonsets',
        'list-deployments'          => 'cloud::prometheus::direct::kubernetes::mode::listdeployments',
        'list-namespaces'           => 'cloud::prometheus::direct::kubernetes::mode::listnamespaces',
        'list-nodes'                => 'cloud::prometheus::direct::kubernetes::mode::listnodes',
        'list-services'             => 'cloud::prometheus::direct::kubernetes::mode::listservices',
        'namespace-status'          => 'cloud::prometheus::direct::kubernetes::mode::namespacestatus',
        'node-status'               => 'cloud::prometheus::direct::kubernetes::mode::nodestatus',
    );

    $self->{custom_modes}{api} = 'cloud::prometheus::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Kubernetes metrics through Prometheus server
using the Kubernetes kube-state-metrics add-on agent.

=cut
