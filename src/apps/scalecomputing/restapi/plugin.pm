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

package apps::scalecomputing::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'cluster-status'             => 'apps::scalecomputing::restapi::mode::clusterstatus',
        'drive-usage'                => 'apps::scalecomputing::restapi::mode::driveusage',
        'list-clusters'              => 'apps::scalecomputing::restapi::mode::listclusters',
        'list-drives'                => 'apps::scalecomputing::restapi::mode::listdrives',
        'list-nodes'                 => 'apps::scalecomputing::restapi::mode::listnodes',
        'list-vdomain-block-devices' => 'apps::scalecomputing::restapi::mode::listvdomainblockdevs',
        'list-vdomains'              => 'apps::scalecomputing::restapi::mode::listvdomains',
        'node-usage'                 => 'apps::scalecomputing::restapi::mode::nodeusage',
        'vdomain-block-device-usage' => 'apps::scalecomputing::restapi::mode::vdomainblockdevusage',
        'vdomain-status'             => 'apps::scalecomputing::restapi::mode::vdomainstatus',
    };

    $self->{custom_modes}->{api} = 'apps::scalecomputing::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Scale Computing through Scale Computing HyperCore API

=cut
