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

package apps::vmware::vsphere8::esx::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'cpu'         => 'apps::vmware::vsphere8::esx::mode::cpu',
        'discovery'   => 'apps::vmware::vsphere8::esx::mode::discovery',
        'disk-io'     => 'apps::vmware::vsphere8::esx::mode::diskio',
        'host-status' => 'apps::vmware::vsphere8::esx::mode::hoststatus',
        'memory'      => 'apps::vmware::vsphere8::esx::mode::memory',
        'network'     => 'apps::vmware::vsphere8::esx::mode::network',
        'power'       => 'apps::vmware::vsphere8::esx::mode::power',
        'swap'        => 'apps::vmware::vsphere8::esx::mode::swap',
    };

    $self->{custom_modes}->{api} = 'apps::vmware::vsphere8::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Monitor VMware physical hosts through vSphere 8 REST API.

=cut
