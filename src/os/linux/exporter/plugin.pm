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

package os::linux::exporter::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'cpu'             => 'os::linux::exporter::mode::cpu',
        'cpu-detailed'    => 'os::linux::exporter::mode::cpudetailed',
        'interface'       => 'os::linux::exporter::mode::interface',
        'list-interfaces' => 'os::linux::exporter::mode::listinterfaces',
        'list-storages'   => 'os::linux::exporter::mode::liststorages',
        'load'            => 'os::linux::exporter::mode::load',
        'memory'          => 'os::linux::exporter::mode::memory',
        'storage'         => 'os::linux::exporter::mode::storage'
    );

    $self->{custom_modes}{web} = 'centreon::common::monitoring::openmetrics::custom::web';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Linux OS-based host metrics using Node Exporter's metrics.

See https://github.com/prometheus/node_exporter for informations about
available metrics.

=cut
