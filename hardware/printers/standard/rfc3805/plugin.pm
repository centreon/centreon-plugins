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

package hardware::printers::standard::rfc3805::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'cover-status'              => 'hardware::printers::standard::rfc3805::mode::coverstatus',
        'hardware-device'           => 'snmp_standard::mode::hardwaredevice',
        'markersupply-usage'        => 'hardware::printers::standard::rfc3805::mode::markersupply',
        'marker-impression'         => 'hardware::printers::standard::rfc3805::mode::markerimpression',
        'papertray-usage'           => 'hardware::printers::standard::rfc3805::mode::papertray',
        'printer-error'             => 'snmp_standard::mode::printererror',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check printers compatible RFC3805 (Printer MIB v2) in SNMP.
Don't know if you can have multiple printer devices at once. So it's not managed yet.

=cut
