#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::proxmox::ve::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'list-nodes'        => 'apps::proxmox::ve::restapi::mode::listnodes',
        'list-storages'     => 'apps::proxmox::ve::restapi::mode::liststorages',
        'list-vms'          => 'apps::proxmox::ve::restapi::mode::listvms',
        'node-usage'        => 'apps::proxmox::ve::restapi::mode::nodeusage',
        'storage-usage'     => 'apps::proxmox::ve::restapi::mode::storageusage',
        'version'           => 'apps::proxmox::ve::restapi::mode::version',
        'vm-usage'          => 'apps::proxmox::ve::restapi::mode::vmusage'
    };

    $self->{custom_modes}->{api} = 'apps::proxmox::ve::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Proxmox VE ressources through its HTTPS remote API.

API documentation can be checked at https://pve.proxmox.com/pve-docs/api-viewer/.

Requirements: Proxmox VE 5.x.

=over 8

=back

=cut
