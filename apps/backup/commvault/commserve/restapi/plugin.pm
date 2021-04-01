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
# Authors : Roman Morandell - ivertix
#

package apps::backup::commvault::commserve::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'alerts'                => 'apps::backup::commvault::commserve::restapi::mode::alerts',
        'jobs'                  => 'apps::backup::commvault::commserve::restapi::mode::jobs',
        'list-media-agents'     => 'apps::backup::commvault::commserve::restapi::mode::listmediaagents',
        'list-storage-policies' => 'apps::backup::commvault::commserve::restapi::mode::liststoragepolicies',
        'media-agents'          => 'apps::backup::commvault::commserve::restapi::mode::mediaagents',
        'storage-pools'         => 'apps::backup::commvault::commserve::restapi::mode::storagepools'
    };

    $self->{custom_modes}->{api} = 'apps::backup::commvault::commserve::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Commvault Commserve using Rest API.

=over 8

=back

=cut
