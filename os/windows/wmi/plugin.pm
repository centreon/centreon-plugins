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

package os::windows::wmi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'cpu'              => 'os::windows::wmi::mode::cpu',
        'interfaces'       => 'snmp_standard::mode::interfaces',
        'list-interfaces'  => 'os::windows::wmi::mode::listinterfaces',
        'list-processes'   => 'snmp_standard::mode::listprocesses',
        'list-services'    => 'os::windows::snmp::mode::listservices',
        'list-storages'    => 'snmp_standard::mode::liststorages',
        'memory'           => 'os::windows::wmi::mode::memory',
        'processcount'     => 'os::windows::wmi::mode::processcount',
        'service'          => 'os::windows::snmp::mode::service',
        'storage'          => 'os::windows::wmi::mode::storage',
        'swap'             => 'os::windows::wmi::mode::swap',
        'time'             => 'os::windows::wmi::mode::ntp',
        'uptime'           => 'os::windows::wmi::mode::uptime',
    );

    $self->{custom_modes}->{wmic} = 'os::windows::wmi::custom::wmic';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Windows operating systems with WMI.

=cut
