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

package os::windows::wsman::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_wsman);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'certificates'    => 'os::windows::wsman::mode::certificates',
        'cpu'             => 'os::windows::wsman::mode::cpu',
        'eventlog'        => 'os::windows::wsman::mode::eventlog',
        'files-date'      => 'os::windows::wsman::mode::filesdate',
        'files-size'      => 'os::windows::wsman::mode::filessize',
        'interfaces'      => 'os::windows::wsman::mode::interfaces',
        'list-interfaces' => 'os::windows::wsman::mode::listinterfaces',
        'list-processes'  => 'os::windows::wsman::mode::listprocesses',
        'list-services'   => 'os::windows::wsman::mode::listservices',
        'list-storages'   => 'os::windows::wsman::mode::liststorages',
        'memory'          => 'os::windows::wsman::mode::memory',
        'pages'           => 'os::windows::wsman::mode::pages',
        'pending-reboot'  => 'os::windows::wsman::mode::pendingreboot',
        'processes'       => 'os::windows::wsman::mode::processes',
        'services'        => 'os::windows::wsman::mode::services',
        'storages'        => 'os::windows::wsman::mode::storages',
        'sessions'        => 'os::windows::wsman::mode::sessions',
        'time'            => 'os::windows::wsman::mode::time',
        'updates'         => 'os::windows::wsman::mode::updates',
        'uptime'          => 'os::windows::wsman::mode::uptime'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Windows operating systems through "WinRM" (ws-management protocol).

=cut
