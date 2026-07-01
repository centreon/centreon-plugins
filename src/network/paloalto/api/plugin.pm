#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::paloalto::api::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'environment' => 'network::paloalto::api::mode::environment',
        'ha'          => 'network::paloalto::api::mode::ha',
        'licenses'    => 'network::paloalto::api::mode::licenses',
        'system'      => 'network::paloalto::api::mode::system',
        'ipsec'       => 'network::paloalto::api::mode::ipsec',
        'discovery'   => 'network::paloalto::api::mode::discovery',
        'health'      => 'network::paloalto::api::mode::health',
        'certificate' => 'network::paloalto::api::mode::certificate'
    };

    $self->{custom_modes}->{api} = 'network::paloalto::api::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Palo Alto devices using the PAN-OS XML API.

=cut
