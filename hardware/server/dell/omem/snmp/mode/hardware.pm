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

package hardware::server::dell::omem::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:temperature|psu\.(voltage|power|current)|chassis\.(power|current))$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        default => [
            [ 'other', 'UNKNOWN' ],
            [ 'unknown', 'UNKNOWN' ],
            [ 'ok', 'OK' ],
            [ 'nonCritical', 'WARNING' ],
            [ 'critical', 'CRITICAL' ],
            [ 'nonRecoverable', 'CRITICAL' ]
        ]
    };

    $self->{components_path} = 'hardware::server::dell::omem::snmp::mode::components';
    $self->{components_module} = ['chassis', 'health', 'psu', 'temperature'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->display_system_information();

    push @{$self->{request}}, { oid => '.1.3.6.1.4.1.674.10892.6.3.1' };
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub display_system_information {
    my ($self, %options) = @_;

    my $oid_dmmProductShortName = '.1.3.6.1.4.1.674.10892.6.1.1.2.0';
    my $oid_dmmChassisServiceTag = '.1.3.6.1.4.1.674.10892.6.1.1.6.0';
    my $oid_dmmFirmwareVersion = '.1.3.6.1.4.1.674.10892.6.1.2.1.0';
    my $oid_dmmFirmwareVersion2 = '.1.3.6.1.4.1.674.10892.6.1.2.2.0';

    my $snmp_result = $self->{snmp}->get_leef(oids => [$oid_dmmProductShortName, $oid_dmmChassisServiceTag, $oid_dmmFirmwareVersion, $oid_dmmFirmwareVersion2]);
    $self->{output}->output_add(
        long_msg => sprintf(
            "Product Name: %s, Service Tag: %s, Firmware Version of MM1: %s, Firmware Version of MM2: %s",
            defined($snmp_result->{$oid_dmmProductShortName}) ? centreon::plugins::misc::trim($snmp_result->{$oid_dmmProductShortName}) : 'unknown',
            defined($snmp_result->{$oid_dmmChassisServiceTag}) ? $snmp_result->{$oid_dmmChassisServiceTag} : 'unknown',
            defined($snmp_result->{$oid_dmmFirmwareVersion}) ? $snmp_result->{$oid_dmmFirmwareVersion} : 'unknown',
            defined($snmp_result->{$oid_dmmFirmwareVersion2}) ? $snmp_result->{$oid_dmmFirmwareVersion2} : 'unknown'
        )
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware (health, temperatures, power supplies metrics and chassis metrics).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'health', 'temperature', 'chassis', 'psu'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan)
Can also exclude specific instance: --filter=health,2

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='health,CRITICAL,^(?!(ok)$)'

=item B<--warning>

Set warning threshold for temperature (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for temperature (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut
