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

package os::linux::local::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'cpu'               => 'os::linux::local::mode::cpu',
        'cpu-detailed'      => 'os::linux::local::mode::cpudetailed',
        'cmd-return'        => 'os::linux::local::mode::cmdreturn',
        'connections'       => 'os::linux::local::mode::connections',
        'directlvm-usage'   => 'os::linux::local::mode::directlvmusage',
        'discovery-nmap'    => 'os::linux::local::mode::discoverynmap',
        'discovery-snmp'    => 'os::linux::local::mode::discoverysnmp',
        'diskio'            => 'os::linux::local::mode::diskio',
        'files-size'        => 'os::linux::local::mode::filessize',
        'files-date'        => 'os::linux::local::mode::filesdate',
        'inodes'            => 'os::linux::local::mode::inodes',
        'load'              => 'os::linux::local::mode::loadaverage',
        'list-interfaces'   => 'os::linux::local::mode::listinterfaces',
        'list-partitions'   => 'os::linux::local::mode::listpartitions',
        'list-storages'     => 'os::linux::local::mode::liststorages',
        'memory'            => 'os::linux::local::mode::memory',
        'mountpoint'        => 'os::linux::local::mode::mountpoint',
        'open-files'        => 'os::linux::local::mode::openfiles',
        'ntp'               => 'os::linux::local::mode::ntp',
        'packet-errors'     => 'os::linux::local::mode::packeterrors',
        'paging'            => 'os::linux::local::mode::paging',
        'pending-updates'   => 'os::linux::local::mode::pendingupdates',
        'process'           => 'os::linux::local::mode::process',
        'quota'             => 'os::linux::local::mode::quota',
        'storage'           => 'os::linux::local::mode::storage',
        'swap'              => 'os::linux::local::mode::swap',
        'systemd-sc-status' => 'os::linux::local::mode::systemdscstatus',
        'traffic'           => 'os::linux::local::mode::traffic',
        'uptime'            => 'os::linux::local::mode::uptime'
    };

    $self->{custom_modes}->{cli} = 'os::linux::local::custom::cli';

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Linux through local commands (the plugin can use SSH).

=cut
