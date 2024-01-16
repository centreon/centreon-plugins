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

package apps::java::jvm::actuator::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'class-count'      => 'apps::java::jvm::actuator::mode::classcount',
        'cpu-load'         => 'apps::java::jvm::actuator::mode::cpuload',
        'fd-usage'         => 'apps::java::jvm::actuator::mode::fdusage',
        'load-average'     => 'apps::java::jvm::actuator::mode::loadaverage',
        'memory'           => 'apps::java::jvm::actuator::mode::memory',
        'memory-detailed'  => 'apps::java::jvm::actuator::mode::memorydetailed',
        'threads'          => 'apps::java::jvm::actuator::mode::threads'
    };

    $self->{custom_modes}->{standard} = 'centreon::common::protocols::actuator::custom::standard';
    $self->{custom_modes}->{centreonmap} = 'centreon::common::protocols::actuator::custom::centreonmap';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Java Virtual Machine with Actuator in HTTP.

=cut
