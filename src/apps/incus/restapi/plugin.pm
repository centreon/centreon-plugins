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

package apps::incus::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'instances'      => 'apps::incus::restapi::mode::instances',
        'instance-usage' => 'apps::incus::restapi::mode::instanceusage',
        'storage'        => 'apps::incus::restapi::mode::storage',
        'warnings'       => 'apps::incus::restapi::mode::warnings',
        'networks'       => 'apps::incus::restapi::mode::networks',
        'cluster'        => 'apps::incus::restapi::mode::cluster',
        'snapshots'      => 'apps::incus::restapi::mode::snapshots',
        'operations'     => 'apps::incus::restapi::mode::operations'
    };

    $self->{custom_modes}->{api} = 'apps::incus::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check an Incus daemon through its HTTPS REST API (https://linuxcontainers.org/incus/docs/main/rest-api/).

=cut
