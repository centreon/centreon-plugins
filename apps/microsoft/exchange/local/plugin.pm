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

package apps::microsoft::exchange::local::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'activesync-mailbox'   => 'apps::microsoft::exchange::local::mode::activesyncmailbox',
        'databases'            => 'apps::microsoft::exchange::local::mode::databases',
        'list-databases'       => 'apps::microsoft::exchange::local::mode::listdatabases',
        'imap-mailbox'         => 'apps::microsoft::exchange::local::mode::imapmailbox',
        'mailboxes'            => 'apps::microsoft::exchange::local::mode::mailboxes',
        'mapi-mailbox'         => 'apps::microsoft::exchange::local::mode::mapimailbox',
        'outlook-webservices'  => 'apps::microsoft::exchange::local::mode::outlookwebservices',
        'owa-mailbox'          => 'apps::microsoft::exchange::local::mode::owamailbox',
        'queues'               => 'apps::microsoft::exchange::local::mode::queues',
        'replication-health'   => 'apps::microsoft::exchange::local::mode::replicationhealth',
        'services'             => 'apps::microsoft::exchange::local::mode::services'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Windows Exchange 2010/2016 locally.

=cut
