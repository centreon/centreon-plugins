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

package cloud::kubernetes::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'cluster-events'                => 'cloud::kubernetes::mode::clusterevents',
        'cronjob-status'                => 'cloud::kubernetes::mode::cronjobstatus',
        'daemonset-status'              => 'cloud::kubernetes::mode::daemonsetstatus',
        'deployment-status'             => 'cloud::kubernetes::mode::deploymentstatus',
        'discovery-nodes'               => 'cloud::kubernetes::mode::discoverynodes',
        'list-cronjobs'                 => 'cloud::kubernetes::mode::listcronjobs',
        'list-daemonsets'               => 'cloud::kubernetes::mode::listdaemonsets',
        'list-deployments'              => 'cloud::kubernetes::mode::listdeployments',
        'list-ingresses'                => 'cloud::kubernetes::mode::listingresses',
        'list-namespaces'               => 'cloud::kubernetes::mode::listnamespaces',
        'list-nodes'                    => 'cloud::kubernetes::mode::listnodes',
        'list-persistentvolumes'        => 'cloud::kubernetes::mode::listpersistentvolumes',
        'list-pods'                     => 'cloud::kubernetes::mode::listpods',
        'list-replicasets'              => 'cloud::kubernetes::mode::listreplicasets',
        'list-replicationcontrollers'   => 'cloud::kubernetes::mode::listreplicationcontrollers',
        'list-services'                 => 'cloud::kubernetes::mode::listservices',
        'list-statefulsets'             => 'cloud::kubernetes::mode::liststatefulsets',
        'node-status'                   => 'cloud::kubernetes::mode::nodestatus',
        'node-usage'                    => 'cloud::kubernetes::mode::nodeusage',
        'persistentvolume-status'       => 'cloud::kubernetes::mode::persistentvolumestatus',
        'pod-status'                    => 'cloud::kubernetes::mode::podstatus',
        'replicaset-status'             => 'cloud::kubernetes::mode::replicasetstatus',
        'replicationcontroller-status'  => 'cloud::kubernetes::mode::replicationcontrollerstatus',
        'statefulset-status'            => 'cloud::kubernetes::mode::statefulsetstatus',
    );

    $self->{custom_modes}{api} = 'cloud::kubernetes::custom::api';
    $self->{custom_modes}{kubectl} = 'cloud::kubernetes::custom::kubectl';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Kubernetes cluster using CLI (kubectl) or RestAPI.

=cut
