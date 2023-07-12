#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package hardware::ups::ees::vertiv::snmp::plugin;
use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'system'      => 'hardware::ups::ees::vertiv::snmp::mode::system',
        'battery'     => 'hardware::ups::ees::vertiv::snmp::mode::battery',
        'input'       => 'hardware::ups::ees::vertiv::snmp::mode::input',
        'temperature' => 'hardware::ups::ees::vertiv::snmp::mode::temperature',
        'rectifier'   => 'hardware::ups::ees::vertiv::snmp::mode::rectifier',
        'uptime'      => 'hardware::ups::ees::vertiv::snmp::mode::uptime'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Emerson Vertiv in SNMP.

=cut