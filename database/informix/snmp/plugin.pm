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

package database::informix::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'archivelevel0'     => 'database::informix::snmp::mode::archivelevel0',
        'chunk-status'      => 'database::informix::snmp::mode::chunkstatus',
        'dbspace-usage'     => 'database::informix::snmp::mode::dbspaceusage',
        'global-cache'      => 'database::informix::snmp::mode::globalcache',
        'list-dbspaces'     => 'database::informix::snmp::mode::listdbspaces',
        'list-instances'    => 'database::informix::snmp::mode::listinstances',
        'lock-stats'        => 'database::informix::snmp::mode::lockstats',
        'logfile-usage'     => 'database::informix::snmp::mode::logfileusage',
        'sessions'          => 'database::informix::snmp::mode::sessions',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Informix in SNMP.

=cut
