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

package network::cisco::smallbusiness::standard::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'cpu'                  => 'centreon::common::cisco::smallbusiness::snmp::mode::cpu',
        'environment'          => 'centreon::common::cisco::smallbusiness::snmp::mode::environment',
        'interfaces'           => 'snmp_standard::mode::interfaces',
        'list-interfaces'      => 'snmp_standard::mode::listinterfaces',
        'list-spanning-trees'  => 'snmp_standard::mode::listspanningtrees',
        'spanning-tree'        => 'snmp_standard::mode::spanningtree',
        'stack'                => 'centreon::common::cisco::smallbusiness::snmp::mode::stack',
        'uptime'               => 'snmp_standard::mode::uptime',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Cisco SB series switches in SNMP.

=cut
