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

package network::arkoon::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'inodes'           => 'snmp_standard::mode::inodes',
        'interfaces'       => 'snmp_standard::mode::interfaces',
        'list-interfaces'  => 'snmp_standard::mode::listinterfaces',
        'load'             => 'snmp_standard::mode::loadaverage',
        'memory'           => 'snmp_standard::mode::memory',
        'processcount'     => 'snmp_standard::mode::processcount',
        'swap'             => 'snmp_standard::mode::swap',
        'uptime'           => 'snmp_standard::mode::uptime',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Arkoon firewall in SNMP.
!!! Be careful: ifAlias and ifName are empty. Use --oid-filter and --oid-display on ifDesc !!!

=cut
