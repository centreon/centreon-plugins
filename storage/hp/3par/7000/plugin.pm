#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::hp::3par::7000::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
                         'physicaldisk'	=> 'storage::hp::3par::7000::mode::physicaldisk',
                         'psu'			=> 'storage::hp::3par::7000::mode::psu',
                         'node'         => 'storage::hp::3par::7000::mode::node',
                         'battery'		=> 'storage::hp::3par::7000::mode::battery', 
                         'wsapi'		=> 'storage::hp::3par::7000::mode::wsapi',
                         'cim'			=> 'storage::hp::3par::7000::mode::cim',
                         'temperature'	=> 'storage::hp::3par::7000::mode::temperature',
                         'storage'		=> 'storage::hp::3par::7000::mode::storage',
                         'iscsi'		=> 'storage::hp::3par::7000::mode::iscsi',
                         'volume'		=> 'storage::hp::3par::7000::mode::volume',
						);

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check HP 3par 7000 series in SSH.

=cut
