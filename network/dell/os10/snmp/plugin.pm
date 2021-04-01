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

package network::dell::os10::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'cpu'             => 'snmp_standard::mode::cpu',
        'disk-usage'      => 'snmp_standard::mode::diskusage',
        'hardware'        => 'network::dell::os10::snmp::mode::hardware',
        'inodes'          => 'snmp_standard::mode::inodes',
        'interfaces'      => 'snmp_standard::mode::interfaces',
        'load'            => 'snmp_standard::mode::loadaverage',
        'list-interfaces' => 'snmp_standard::mode::listinterfaces',
        'memory'          => 'snmp_standard::mode::memory',
        'swap'            => 'snmp_standard::mode::swap',
        'uptime'          => 'snmp_standard::mode::uptime'
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Dell OS10 Operating System in SNMP. It's based on Linux.
The legacy version is 0S9, FTOS or Force10 operating system.

=cut
