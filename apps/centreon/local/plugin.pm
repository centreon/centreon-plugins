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

package apps::centreon::local::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'bamservice'               => 'apps::centreon::local::mode::bamservice',
        'broker-stats'             => 'apps::centreon::local::mode::brokerstats',
        'centengine-stats'         => 'apps::centreon::local::mode::centenginestats',
        'centreon-plugins-version' => 'apps::centreon::local::mode::centreonpluginsversion',
        'downtime-trap'            => 'apps::centreon::local::mode::downtimetrap',
        'dummy'                    => 'apps::centreon::local::mode::dummy',
        'metaservice'              => 'apps::centreon::local::mode::metaservice',
        'not-so-dummy'             => 'apps::centreon::local::mode::notsodummy',
        'retention-broker'         => 'apps::centreon::local::mode::retentionbroker',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Specific Centreon Indicators.

=cut
