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

package network::stormshield::api::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'cpu'              => 'network::stormshield::api::mode::cpu',
        'ha'               => 'network::stormshield::api::mode::ha',
        'hardware'         => 'network::stormshield::api::mode::hardware',
        'health'           => 'network::stormshield::api::mode::health',
        'interfaces'       => 'network::stormshield::api::mode::interfaces',
        'list-interfaces'  => 'network::stormshield::api::mode::listinterfaces',
        'list-vpn-tunnels' => 'network::stormshield::api::mode::listvpntunnels',
        'memory'           => 'network::stormshield::api::mode::memory',
        'uptime'           => 'network::stormshield::api::mode::uptime',
        'vpn-tunnels'      => 'network::stormshield::api::mode::vpntunnels'
    };

    $self->{custom_modes}->{api} = 'network::stormshield::api::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Stormshield through SSL API.

=cut
