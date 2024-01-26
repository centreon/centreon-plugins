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

package storage::emc::vplex::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'cluster-communication' => 'storage::emc::vplex::restapi::mode::clustercommunication',
        'cluster-devices'       => 'storage::emc::vplex::restapi::mode::clusterdevices',
        'directors'             => 'storage::emc::vplex::restapi::mode::directors',
        'distributed-devices'   => 'storage::emc::vplex::restapi::mode::distributeddevices',
        'fans'                  => 'storage::emc::vplex::restapi::mode::fans',
        'psus'                  => 'storage::emc::vplex::restapi::mode::psus',
        'storage-volumes'       => 'storage::emc::vplex::restapi::mode::storagevolumes'
    };

    $self->{custom_modes}->{apiv1} = 'storage::emc::vplex::restapi::custom::apiv1';
    $self->{custom_modes}->{apiv2} = 'storage::emc::vplex::restapi::custom::apiv2';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check EMC Vplex through HTTP/REST API.

=cut
