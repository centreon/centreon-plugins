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

package storage::panzura::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'cpu-detailed'     => 'snmp_standard::mode::cpudetailed',
        'cpu-cloud'        => 'storage::panzura::snmp::mode::cpucloud',
        'diskio'           => 'snmp_standard::mode::diskio',
        'disk-usage-cloud' => 'snmp_standard::mode::diskusage',
        'disk-usage-local' => 'storage::panzura::snmp::mode::diskusagelocal',
        'load'             => 'snmp_standard::mode::loadaverage',
        'interfaces'       => 'snmp_standard::mode::interfaces',
        'list-diskspath'   => 'snmp_standard::mode::listdiskspath',
        'list-interfaces'  => 'snmp_standard::mode::listinterfaces',
        'list-storages'    => 'snmp_standard::mode::liststorages',
        'memory'           => 'storage::panzura::snmp::mode::memory',
        'ratios'           => 'storage::panzura::snmp::mode::ratios',
        'swap'             => 'snmp_standard::mode::swap',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Panzura storage in SNMP.

=cut
