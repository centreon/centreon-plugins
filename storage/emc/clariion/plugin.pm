#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package storage::emc::clariion::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                         'cache'        => 'centreon::common::emc::navisphere::mode::cache',
                         'controller'   => 'centreon::common::emc::navisphere::mode::controller',
                         'disk'         => 'centreon::common::emc::navisphere::mode::disk',
                         'sp'           => 'centreon::common::emc::navisphere::mode::sp',
                         'faults'       => 'centreon::common::emc::navisphere::mode::faults',
                         'list-luns'    => 'centreon::common::emc::navisphere::mode::listluns',
                         'sp-info'      => 'centreon::common::emc::navisphere::mode::spinfo',
                         'port-state'   => 'centreon::common::emc::navisphere::mode::portstate',
                         'hba-state'    => 'centreon::common::emc::navisphere::mode::hbastate',
                        );
    $self->{custom_modes}{clariion} = 'centreon::common::emc::navisphere::custom::custom';

    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->SUPER::init(%options);    
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check EMC Clariion with 'navicli/naviseccli'.

=over 8

=back

=cut
