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

package cloud::kubernetes::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'daemonset-status'  => 'cloud::kubernetes::restapi::mode::daemonsetstatus',
        'deployment-status' => 'cloud::kubernetes::restapi::mode::deploymentstatus',
        'list-daemonsets'   => 'cloud::kubernetes::restapi::mode::listdaemonsets',
        'list-deployments'  => 'cloud::kubernetes::restapi::mode::listdeployments',
        'list-ingresses'    => 'cloud::kubernetes::restapi::mode::listingresses',
        'list-namespaces'   => 'cloud::kubernetes::restapi::mode::listnamespaces',
        'list-nodes'        => 'cloud::kubernetes::restapi::mode::listnodes',
        'list-pods'         => 'cloud::kubernetes::restapi::mode::listpods',
        'list-replicasets'  => 'cloud::kubernetes::restapi::mode::listreplicasets',
        'list-services'     => 'cloud::kubernetes::restapi::mode::listservices',
        'list-statefulsets' => 'cloud::kubernetes::restapi::mode::liststatefulsets',
        'pod-status'        => 'cloud::kubernetes::restapi::mode::podstatus',
    );

    $self->{custom_modes}{api} = 'cloud::kubernetes::restapi::custom::api';
    return $self;
}

sub init {
    my ( $self, %options ) = @_;

    $self->SUPER::init(%options);
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Kubernetes cluster using API.

=cut
