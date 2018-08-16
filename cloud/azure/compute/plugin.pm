#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package cloud::azure::compute::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new( package => __PACKAGE__, %options );
    bless $self, $class;

    $self->{version} = '0.1';
    %{ $self->{modes} } = (
        'cpu'                   => 'cloud::azure::compute::mode::cpu',
        'diskio'                => 'cloud::azure::compute::mode::diskio',
        'list-resources'        => 'cloud::azure::compute::mode::listresources',
        'list-vms'              => 'cloud::azure::compute::mode::listvms',
        'network'               => 'cloud::azure::compute::mode::network',
        'vm-sizes'              => 'cloud::azure::compute::mode::vmsizes',
        'vms-state'             => 'cloud::azure::compute::mode::vmsstate',
    );

    $self->{custom_modes}{azcli} = 'cloud::azure::custom::azcli';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Microsoft Azure compute provider.

=cut
