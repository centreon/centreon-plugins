#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::f5::bigip::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
                         'connections'          => 'network::f5::bigip::mode::connections',
                         'failover'             => 'network::f5::bigip::mode::failover',
                         'hardware'             => 'network::f5::bigip::mode::hardware',
                         'list-nodes'           => 'network::f5::bigip::mode::listnodes',
                         'list-pools'           => 'network::f5::bigip::mode::listpools',
                         'list-virtualservers'  => 'network::f5::bigip::mode::listvirtualservers',
                         'node-status'          => 'network::f5::bigip::mode::nodestatus',
                         'pool-status'          => 'network::f5::bigip::mode::poolstatus',
                         'virtualserver-status' => 'network::f5::bigip::mode::virtualserverstatus',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check F-5 hardware in SNMP.
Please use plugin SNMP Linux for system checks ('cpu', 'memory', 'traffic',...).

=cut
