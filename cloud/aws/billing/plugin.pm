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

package cloud::aws::billing::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new( package => __PACKAGE__, %options );
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'estimated-charges' => 'cloud::aws::billing::mode::estimatedcharges',
        'list-services'     => 'cloud::aws::billing::mode::listservices'
    };

    $self->{customdefault} = {
        paws   => { region => 'us-east-1' },
        awscli => { region => 'us-east-1' }
    };

    $self->{custom_modes}->{paws} = 'cloud::aws::custom::paws';
    $self->{custom_modes}->{awscli} = 'cloud::aws::custom::awscli';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Amazon Billing.

Works for 'us-east-1' region only.

=cut
