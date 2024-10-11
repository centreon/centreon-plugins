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

package network::huawei::wlc::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'ap-health'       => 'network::huawei::wlc::snmp::mode::aphealth',
        'ap-radio'        => 'network::huawei::wlc::snmp::mode::apradio',
        'ap-status'       => 'network::huawei::wlc::snmp::mode::apstatus',
        'cpu'             => 'centreon::common::huawei::standard::snmp::mode::cpu',
        'hardware'        => 'centreon::common::huawei::standard::snmp::mode::hardware',
        'interfaces'      => 'centreon::common::huawei::standard::snmp::mode::interfaces',
        'list-aps'        => 'network::huawei::wlc::snmp::mode::listaps',
        'list-interfaces' => 'snmp_standard::mode::listinterfaces',
        'list-radios'     => 'network::huawei::wlc::snmp::mode::listradios',
        'memory'          => 'centreon::common::huawei::standard::snmp::mode::memory',
        'uptime'          => 'snmp_standard::mode::uptime',
        'wlan-global'     => 'network::huawei::wlc::snmp::mode::wlanglobal'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Huawei WLC in SNMP.

=cut
