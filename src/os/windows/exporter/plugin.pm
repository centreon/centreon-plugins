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

package os::windows::exporter::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'cpu'             => 'os::windows::exporter::mode::cpu',
        'interface'       => 'os::windows::exporter::mode::interface',
        'list-interfaces' => 'os::windows::exporter::mode::listinterfaces',
        'list-services'   => 'os::windows::exporter::mode::listservices',
        'list-storages'   => 'os::windows::exporter::mode::liststorages',
        'memory'          => 'os::windows::exporter::mode::memory',
        'service'         => 'os::windows::exporter::mode::service',
        'storage'         => 'os::windows::exporter::mode::storage'
    );

    $self->{custom_modes}{web} = 'centreon::common::monitoring::openmetrics::custom::web';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Windows OS-based host metrics using Windows Exporter's metrics.

See https://github.com/prometheus-community/windows_exporter for informations
about available metrics.

=cut
