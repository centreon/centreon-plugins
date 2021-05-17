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

package cloud::azure::management::applicationinsights::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new( package => __PACKAGE__, %options );
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'availability'    => 'cloud::azure::management::applicationinsights::mode::availability',
        'browser-timings' => 'cloud::azure::management::applicationinsights::mode::browsertimings',
        'cpu'             => 'cloud::azure::management::applicationinsights::mode::cpu',
        'discovery'       => 'cloud::azure::management::applicationinsights::mode::discovery',
        'exceptions'      => 'cloud::azure::management::applicationinsights::mode::exceptions',
        'external-calls'  => 'cloud::azure::management::applicationinsights::mode::externalcalls',
        'io-operations'   => 'cloud::azure::management::applicationinsights::mode::iooperations',
        'health'          => 'cloud::azure::management::applicationinsights::mode::health',
        'memory'          => 'cloud::azure::management::applicationinsights::mode::memory',
        'page-views'      => 'cloud::azure::management::applicationinsights::mode::pageviews',
        'requests'        => 'cloud::azure::management::applicationinsights::mode::requests',
    };

    $self->{custom_modes}->{azcli} = 'cloud::azure::custom::azcli';
    $self->{custom_modes}->{api} = 'cloud::azure::custom::api';
    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(arguments => {
        'api-version:s'  => { name => 'api_version', default => '2018-01-01' },
    });

    $self->SUPER::init(%options);
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Microsoft Azure Application Insights resources.

=cut
