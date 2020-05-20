#
# Copyright 2015 Centreon (http://www.centreon.com/)
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
# Authors : Thomas Gourdin thomas.gourdin@gmail.com

package hardware::devices::timelinkmicro::tms6001::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'alarms'     => 'hardware::devices::timelinkmicro::tms6001::snmp::mode::alarms',
        'antenna'    => 'hardware::devices::timelinkmicro::tms6001::snmp::mode::antenna',
        'frequency'  => 'hardware::devices::timelinkmicro::tms6001::snmp::mode::frequency',
        'gnss'       => 'hardware::devices::timelinkmicro::tms6001::snmp::mode::gnss',
        'satellites' => 'hardware::devices::timelinkmicro::tms6001::snmp::mode::satellites',
        'time'       => 'hardware::devices::timelinkmicro::tms6001::snmp::mode::time'
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check timelinkmicro TMS6001 NTP servers through SNMP

=cut
