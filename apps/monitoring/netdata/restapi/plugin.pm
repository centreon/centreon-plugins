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

package apps::monitoring::netdata::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'alarms'          => 'apps::monitoring::netdata::restapi::mode::alarms',
        'cpu'             => 'apps::monitoring::netdata::restapi::mode::cpu',
        'disks'           => 'apps::monitoring::netdata::restapi::mode::disks',
        'get-chart'       => 'apps::monitoring::netdata::restapi::mode::getchart',
        'inodes'          => 'apps::monitoring::netdata::restapi::mode::inodes',
        'list-charts'     => 'apps::monitoring::netdata::restapi::mode::listcharts',
        'list-disks'      => 'apps::monitoring::netdata::restapi::mode::listdisks',
        'list-interfaces' => 'apps::monitoring::netdata::restapi::mode::listinterfaces',
        'load'            => 'apps::monitoring::netdata::restapi::mode::load',
        'memory'          => 'apps::monitoring::netdata::restapi::mode::memory',
        'swap'            => 'apps::monitoring::netdata::restapi::mode::swap',
        'traffic'         => 'apps::monitoring::netdata::restapi::mode::traffic'
    };

    $self->{custom_modes}->{restapi} = 'apps::monitoring::netdata::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check *nix based servers components using the Netdata agent RestAPI.

=cut
