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

package network::f5::bigip::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'apm'                  => 'network::f5::bigip::snmp::mode::apm',
        'connections'          => 'network::f5::bigip::snmp::mode::connections',
        'failover'             => 'network::f5::bigip::snmp::mode::failover',
        'hardware'             => 'network::f5::bigip::snmp::mode::hardware',
        'list-nodes'           => 'network::f5::bigip::snmp::mode::listnodes',
        'list-pools'           => 'network::f5::bigip::snmp::mode::listpools',
        'list-trunks'          => 'network::f5::bigip::snmp::mode::listtrunks',
        'list-virtualservers'  => 'network::f5::bigip::snmp::mode::listvirtualservers',
        'node-status'          => 'network::f5::bigip::snmp::mode::nodestatus',
        'pool-status'          => 'network::f5::bigip::snmp::mode::poolstatus',
        'tmm-usage'            => 'network::f5::bigip::snmp::mode::tmmusage',
        'trunks'               => 'network::f5::bigip::snmp::mode::trunks',
        'virtualserver-status' => 'network::f5::bigip::snmp::mode::virtualserverstatus'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check F-5 hardware in SNMP.
Please use plugin SNMP Linux for system checks ('cpu', 'memory', 'traffic',...).

=cut
