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

package cloud::docker::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.3';
    $self->{modes} = {
        'container-usage'   => 'cloud::docker::restapi::mode::containerusage',
        'list-containers'   => 'cloud::docker::restapi::mode::listcontainers',
        'node-status'       => 'cloud::docker::restapi::mode::nodestatus',
        'service-status'    => 'cloud::docker::restapi::mode::servicestatus'
    };

    $self->{custom_modes}->{api} = 'cloud::docker::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Docker and containers through its HTTPS Remote API (https://docs.docker.com/reference/api/docker_remote_api/).
Requirements: Docker 1.12.0+ and Docker API 1.24+

=cut
