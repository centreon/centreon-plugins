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

package cloud::prometheus::exporters::cadvisor::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'cpu'               => 'cloud::prometheus::exporters::cadvisor::mode::cpu',
        'list-containers'   => 'cloud::prometheus::exporters::cadvisor::mode::listcontainers',
        'load'              => 'cloud::prometheus::exporters::cadvisor::mode::load',
        'memory'            => 'cloud::prometheus::exporters::cadvisor::mode::memory',
        'storage'           => 'cloud::prometheus::exporters::cadvisor::mode::storage',
        'task-state'        => 'cloud::prometheus::exporters::cadvisor::mode::taskstate',
    );

    $self->{custom_modes}{api} = 'cloud::prometheus::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check cAdvisor metrics through Prometheus server.

=cut
