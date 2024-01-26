#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package cloud::azure::compute::aks::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {        
        'allocatable-resources' => 'cloud::azure::compute::aks::mode::allocatableresources',
        'cpu'                   => 'cloud::azure::compute::aks::mode::cpu',
        'discovery'             => 'cloud::azure::compute::aks::mode::discovery',
        'health'                => 'cloud::azure::compute::aks::mode::health',
        'memory'                => 'cloud::azure::compute::aks::mode::memory',
        'node-state'            => 'cloud::azure::compute::aks::mode::nodestate',
        'pod-state'             => 'cloud::azure::compute::aks::mode::podstate',
        'storage'               => 'cloud::azure::compute::aks::mode::storage',
        'traffic'               => 'cloud::azure::compute::aks::mode::traffic',
        'unneeded-nodes'        => 'cloud::azure::compute::aks::mode::unneedednodes',
        'unschedulable-pods'    => 'cloud::azure::compute::aks::mode::unschedulablepods'
    };

    $self->{custom_modes}->{azcli} = 'cloud::azure::custom::azcli';
    $self->{custom_modes}->{api} = 'cloud::azure::custom::api';
    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(arguments => {
        'api-version:s'  => { name => 'api_version', default => '2018-01-01' }
    });

    $self->SUPER::init(%options);
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Microsoft Azure Kubernetes Service.

=cut
