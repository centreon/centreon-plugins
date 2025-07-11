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

package network::juniper::isg::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'cpu'               => 'network::juniper::common::screenos::snmp::mode::cpu',
        'hardware'          => 'network::juniper::common::screenos::snmp::mode::hardware',
        'interfaces'        => 'snmp_standard::mode::interfaces', 
        'list-interfaces'   => 'snmp_standard::mode::listinterfaces',
        'memory'            => 'network::juniper::common::screenos::snmp::mode::memory',
        'sessions'          => 'network::juniper::common::screenos::snmp::mode::sessions'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Juniper Integrated Security Gateways series in SNMP.

=cut
