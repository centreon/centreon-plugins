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

package network::cisco::wlc::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'ap-channel-interference'  => 'centreon::common::airespace::snmp::mode::apchannelinterference',
        'ap-channel-noise'         => 'centreon::common::airespace::snmp::mode::apchannelnoise',
        'ap-status'                => 'centreon::common::airespace::snmp::mode::apstatus',
        'ap-users'                 => 'centreon::common::airespace::snmp::mode::apusers',
        'cpu'                      => 'centreon::common::airespace::snmp::mode::cpu',
        'hardware'                 => 'centreon::common::airespace::snmp::mode::hardware',
        'interfaces'               => 'snmp_standard::mode::interfaces', 
        'list-groups'              => 'centreon::common::airespace::snmp::mode::listgroups',
        'list-interfaces'          => 'snmp_standard::mode::listinterfaces',
        'list-radius-acc-servers'  => 'centreon::common::airespace::snmp::mode::listradiusaccservers',
        'list-radius-auth-servers' => 'centreon::common::airespace::snmp::mode::listradiusauthservers',
        'memory'                   => 'centreon::common::airespace::snmp::mode::memory',
        'radius-acc-servers'       => 'centreon::common::airespace::snmp::mode::radiusaccservers',
        'radius-auth-servers'      => 'centreon::common::airespace::snmp::mode::radiusauthservers'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Cisco Wireless Lan Controller in SNMP.

=cut
