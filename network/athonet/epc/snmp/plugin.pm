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

package network::athonet::epc::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'interfaces-diameter'      => 'network::athonet::epc::snmp::mode::interfacesdiameter',
        'interfaces-lte'           => 'network::athonet::epc::snmp::mode::interfaceslte',
        'interfaces-ga'            => 'network::athonet::epc::snmp::mode::interfacesga',
        'interfaces-gtpc'          => 'network::athonet::epc::snmp::mode::interfacesgtpc',
        'license'                  => 'network::athonet::epc::snmp::mode::license',
        'list-interfaces-diameter' => 'network::athonet::epc::snmp::mode::listinterfacesdiameter',
        'list-interfaces-ga'       => 'network::athonet::epc::snmp::mode::listinterfacesga',
        'list-interfaces-gtpc'     => 'network::athonet::epc::snmp::mode::listinterfacesgtpc',
        'list-interfaces-lte'      => 'network::athonet::epc::snmp::mode::listinterfaceslte',
        'lte'                      => 'network::athonet::epc::snmp::mode::lte'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Athonet ePC in SNMP.

=cut
