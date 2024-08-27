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

package os::as400::connector::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'command'         => 'os::as400::connector::mode::command',
        'disks'           => 'os::as400::connector::mode::disks',
        'jobs'            => 'os::as400::connector::mode::jobs',
        'job-queues'      => 'os::as400::connector::mode::jobqueues',
        'list-disks'      => 'os::as400::connector::mode::listdisks',
        'list-subsystems' => 'os::as400::connector::mode::listsubsystems',
        'message-queue'   => 'os::as400::connector::mode::messagequeue',
        'page-faults'     => 'os::as400::connector::mode::pagefaults',
        'system'          => 'os::as400::connector::mode::system',
        'subsystems'      => 'os::as400::connector::mode::subsystems'
    };

    $self->{custom_modes}->{api} = 'os::as400::connector::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check AS/400 (Systemi) with centreon-as400 connector.

=cut
