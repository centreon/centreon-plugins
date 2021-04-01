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

package storage::quantum::dxi::ssh::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'compaction'             => 'storage::quantum::dxi::ssh::mode::compaction',
        'dedupnas'               => 'storage::quantum::dxi::ssh::mode::dedupnas',
        'dedupvtl'               => 'storage::quantum::dxi::ssh::mode::dedupvtl',
        'disk-usage'             => 'storage::quantum::dxi::ssh::mode::diskusage',
        'health'                 => 'storage::quantum::dxi::ssh::mode::health',
        'hostbus-adapter-status' => 'storage::quantum::dxi::ssh::mode::hostbusadapterstatus',
        'memory'                 => 'storage::quantum::dxi::ssh::mode::memory',
        'network'                => 'storage::quantum::dxi::ssh::mode::network',
        'reclamation'            => 'storage::quantum::dxi::ssh::mode::reclamation',
        'reduction'              => 'storage::quantum::dxi::ssh::mode::reduction',
        'storage-array-status'   => 'storage::quantum::dxi::ssh::mode::storagearraystatus',
        'system-status'          => 'storage::quantum::dxi::ssh::mode::systemstatus',
        'throughput'             => 'storage::quantum::dxi::ssh::mode::throughput',
    );
    $self->{custom_modes}{api} = 'storage::quantum::dxi::ssh::custom::api';

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Quantum DXi series appliances through SSH commands.

=cut
