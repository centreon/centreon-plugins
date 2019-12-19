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
        'daemonset-status'  => 'cloud::kubernetes::mode::daemonsetstatus',
        'deployment-status' => 'cloud::kubernetes::mode::deploymentstatus',
        'list-daemonsets'   => 'cloud::kubernetes::mode::listdaemonsets',
        'list-deployments'  => 'cloud::kubernetes::mode::listdeployments',
        'list-ingresses'    => 'cloud::kubernetes::mode::listingresses',
        'list-namespaces'   => 'cloud::kubernetes::mode::listnamespaces',
        'list-nodes'        => 'cloud::kubernetes::mode::listnodes',
        'list-pods'         => 'cloud::kubernetes::mode::listpods',
        'list-replicasets'  => 'cloud::kubernetes::mode::listreplicasets',
        'list-services'     => 'cloud::kubernetes::mode::listservices',
        'list-statefulsets' => 'cloud::kubernetes::mode::liststatefulsets',
        'node-usage'        => 'cloud::kubernetes::mode::nodeusage',
        'pod-status'        => 'cloud::kubernetes::mode::podstatus',
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
