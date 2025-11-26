#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package cloud::openstack::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        # Mode host "OpenStack"
        'discovery'         => 'cloud::openstack::restapi::mode::discovery',
        'list-services'     => 'cloud::openstack::restapi::mode::listservices',
        'service'           => 'cloud::openstack::restapi::mode::service',

        # Mode host "Project/Tenant"
        'project-discovery' => 'cloud::openstack::restapi::mode::projectdiscovery',
        'volume'            => 'cloud::openstack::restapi::mode::volume',
        'hypervisor'        => 'cloud::openstack::restapi::mode::hypervisor',
        'network'           => 'cloud::openstack::restapi::mode::network',
        'port'              => 'cloud::openstack::restapi::mode::port',
        'loadbalancer'      => 'cloud::openstack::restapi::mode::loadbalancer',
        # Mode host "Porjetct/Tenant" + Mode "host" ( when --host-discovery is set )
        'instance'          => 'cloud::openstack::restapi::mode::instance',
    };

    $self->{custom_modes}->{cli} = 'cloud::openstack::restapi::custom::api';

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check OpenStack Rest API.

=cut
