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

package network::alcatel::isam::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(cardtemperature|sfp\.(temperature|voltage|current|txpower|rxpower))$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        sfp => [
            ['noLos', 'OK'],
            ['notAvailable', 'OK'],
            ['los', 'WARNING']
        ]
    };
    
    $self->{components_path} = 'network::alcatel::isam::snmp::mode::components';
    $self->{components_module} = ['cardtemperature', 'sfp'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    my $oid_eqptSlotActualType = '.1.3.6.1.4.1.637.61.1.23.3.1.3';
    my $oid_eqptBoardInventorySerialNumber = '.1.3.6.1.4.1.637.61.1.23.3.1.19';
    push @{$self->{request}}, { oid => $oid_eqptSlotActualType }, { oid => $oid_eqptBoardInventorySerialNumber };
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check Hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'cardtemperature', 'sfp'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=cardtemperature)
Can also exclude specific instance: --filter=cardtemperature,1080.1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='sfp,OK,^los$'

=item B<--warning>

Set warning threshold for 'sfp.temperature', 'cardtemperature' (syntax: type,regexp,threshold)
Example: --warning='sfp.temperature,1.1,30'

=item B<--critical>

Set critical threshold for 'sfp.temperature', 'cardtemperature' (syntax: type,regexp,threshold)
Example: --warning='sfp.temperature,1.1,40'

=back

=cut
