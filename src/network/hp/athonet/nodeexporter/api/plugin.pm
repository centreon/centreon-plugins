#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package network::hp::athonet::nodeexporter::api::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'charging-function'      => 'network::hp::athonet::nodeexporter::api::mode::chargingfunction',
        'cpu'                    => 'cloud::prometheus::exporters::nodeexporter::mode::cpu',
        'cpu-detailed'           => 'cloud::prometheus::exporters::nodeexporter::mode::cpudetailed',
        'diameter-routing-agent' => 'network::hp::athonet::nodeexporter::api::mode::dra',
        'eir'                    => 'network::hp::athonet::nodeexporter::api::mode::eir',
        'interfaces'             => 'cloud::prometheus::exporters::nodeexporter::mode::interfaces',
        'licenses'               => 'network::hp::athonet::nodeexporter::api::mode::licenses',
        'load'                   => 'cloud::prometheus::exporters::nodeexporter::mode::load',
        'memory'                 => 'cloud::prometheus::exporters::nodeexporter::mode::memory',
        'mme'                    => 'network::hp::athonet::nodeexporter::api::mode::mme',
        'nrf'                    => 'network::hp::athonet::nodeexporter::api::mode::nrf',
        'pcf'                    => 'network::hp::athonet::nodeexporter::api::mode::pcf',
        'sgwc'                   => 'network::hp::athonet::nodeexporter::api::mode::sgwc',
        'smf'                    => 'network::hp::athonet::nodeexporter::api::mode::smf',
        'smsf'                   => 'network::hp::athonet::nodeexporter::api::mode::smsf',
        'storage'                => 'cloud::prometheus::exporters::nodeexporter::mode::storage',
        'udm'                    => 'network::hp::athonet::nodeexporter::api::mode::udm',
        'udr'                    => 'network::hp::athonet::nodeexporter::api::mode::udr',
        'upf'                    => 'network::hp::athonet::nodeexporter::api::mode::upf',
        'uptime'                 => 'cloud::prometheus::exporters::nodeexporter::mode::uptime'
    };

    $self->{custom_modes}->{api} = 'network::hp::athonet::nodeexporter::api::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check HP Athonet through Prometheus node exporter API.

=cut
