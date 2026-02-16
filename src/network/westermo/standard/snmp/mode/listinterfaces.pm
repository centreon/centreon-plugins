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

package network::westermo::standard::snmp::mode::listinterfaces;

use base qw(snmp_standard::mode::listinterfaces);

use strict;
use warnings;

sub set_oids_label {
    my ($self, %options) = @_;

    $self->SUPER::set_oids_label(%options);
    $self->{oids_label} = {
        'ifname' => '.1.3.6.1.4.1.16177.2.4.1.1.1.3'
    };
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

1;

__END__

=head1 MODE

=over 8

=item B<--interface>

Define which interfaces to monitor (number expected). Example: 1,2... (empty means 'check all interfaces').

=item B<--name>

Allows you to define the interface (in option --interface) by name instead of OID index. The name matching mode supports regular expressions.

=item B<--speed>

Set interface speed (in Mb).

=item B<--skip-speed0>

Avoid displaying interfaces with bandwidth/speed equal to 0.

=item B<--filter-status>

Filter interfaces based on their status using a regular expression (example: 'up|UP').

=item B<--use-adminstatus>

Display interfaces with C<AdminStatus> 'up'.

=item B<--oid-filter>

Define the OID to be used to filter interfaces (default: C<ifName>).
Available OIDs: C<ifDesc>, C<ifAlias>, C<ifName>).

=item B<--oid-display>

Define the OID that will be used to name the interfaces (default: ifName).
Available OIDs: C<ifDesc>, C<ifAlias>, C<ifName>).

=item B<--display-transform-src> B<--display-transform-dst>

Modify the interface name displayed by using a regular expression.

Example: adding C<--display-transform-src='eth' --display-transform-dst='ens'>  will replace all occurrences of 'eth' with 'ens'

=item B<--add-extra-oid>

Display an OID.
Example: C<--add-extra-oid='alias,.1.3.6.1.2.1.31.1.1.1.18'>
or C<--add-extra-oid='vlan,.1.3.6.1.2.1.31.19,%{instance}\..*'>

=item B<--add-mac-address>

Display interfaces MAC addresses.

=back

=cut
