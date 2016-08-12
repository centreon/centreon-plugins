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

package cloud::docker::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.3';
    %{$self->{modes}} = (
                        'blockio'           => 'cloud::docker::mode::blockio',
                        'containerstate'    => 'cloud::docker::mode::containerstate',
                        'cpu'               => 'cloud::docker::mode::cpu',
                        'image'             => 'cloud::docker::mode::image',
                        'info'              => 'cloud::docker::mode::info',
                        'list-containers'   => 'cloud::docker::mode::listcontainers',
                        'list-nodes'        => 'cloud::docker::mode::listnodes',
                        'memory'            => 'cloud::docker::mode::memory',
                        'nodestate'         => 'cloud::docker::mode::nodestate',
                        'traffic'           => 'cloud::docker::mode::traffic',
                        );

    $self->{custom_modes}{dockerapi} = 'cloud::docker::custom::dockerapi';
    return $self;
}

sub init {
    my ( $self, %options ) = @_;

    $self->SUPER::init(%options);
}


1;

__END__

=head1 PLUGIN DESCRIPTION

Check Docker and containers through its HTTPS Remote API (https://docs.docker.com/reference/api/docker_remote_api/).
Requirements: Docker 1.12.0+ and Docker API 1.24+

=cut
