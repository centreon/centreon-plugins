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

package centreon::common::cisco::standard::snmp::mode::environment;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|voltage|sensor.*)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        fan => [
            ['normal', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
            ['shutdown', 'CRITICAL'],
            ['not present', 'OK'],
            ['not functioning', 'WARNING'],
    
            ['unknown', 'UNKNOWN'],
            ['down', 'CRITICAL'],
            ['up', 'OK']
        ],
        psu => [            
            ['normal', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
            ['shutdown', 'CRITICAL'],
            ['not present', 'OK'],
            ['not functioning', 'WARNING'],

            ['^off*', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['onButFanFail|onButInlinePowerFail', 'WARNING'],
            ['on', 'OK']
        ],
        temperature => [
            ['normal', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
            ['shutdown', 'CRITICAL'],
            ['not present', 'OK'],
            ['not functioning', 'WARNING']
        ],
        voltage => [
            ['normal', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
            ['shutdown', 'CRITICAL'],
            ['not present', 'OK'],
            ['not functioning', 'WARNING']
        ],
        module => [
            ['unknown|mdr', 'UNKNOWN'],
            ['disabled|okButDiagFailed|missing|mismatchWithParent|mismatchConfig|dormant|outOfServiceAdmin|outOfServiceEnvTemp|powerCycled|okButPowerOverWarning|okButAuthFailed|fwMismatchFound|fwDownloadFailure', 'WARNING'],
            ['failed|diagFailed|poweredDown|powerDenied|okButPowerOverCritical', 'CRITICAL'],
            ['boot|selfTest|poweredUp|syncInProgress|upgrading|fwDownloadSuccess|ok', 'OK']
        ],
        physical => [
            ['other', 'UNKNOWN'],
            ['incompatible|unsupported', 'CRITICAL'],
            ['supported', 'OK']
        ],
        sensor => [
            ['ok', 'OK'],
            ['unavailable', 'OK'],
            ['nonoperational', 'CRITICAL']
        ]
    };

    $self->{components_path} = 'centreon::common::cisco::standard::snmp::mode::components';
    $self->{components_module} = ['fan', 'psu', 'temperature', 'voltage', 'module', 'physical', 'sensor'];
}

my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
my $oid_ciscoEnvMonPresent = ".1.3.6.1.4.1.9.9.13.1.1";

my %map_type_mon = (
    1 => 'oldAgs',
    2 => 'ags',
    3 => 'c7000',
    4 => 'ci',
    6 => 'cAccessMon',
    7 => 'cat6000',
    8 => 'ubr7200',
    9 => 'cat4000',
    10 => 'c10000',
    11 => 'osr7600',
    12 => 'c7600',
    13 => 'c37xx',
    14 => 'other'
);

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};

    push @{$self->{request}}, { oid => $oid_entPhysicalDescr }, { oid => $oid_ciscoEnvMonPresent };
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
    while (my ($key, $value) = each %{$self->{results}->{$oid_entPhysicalDescr}}) {
        $self->{results}->{$oid_entPhysicalDescr}->{$key} = centreon::plugins::misc::trim($value);
    }
    $self->{output}->output_add(
        long_msg => sprintf(
            'Environment type: %s', 
            defined($self->{results}->{$oid_ciscoEnvMonPresent}->{$oid_ciscoEnvMonPresent . '.0'}) && defined($map_type_mon{$self->{results}->{$oid_ciscoEnvMonPresent}->{$oid_ciscoEnvMonPresent . '.0'}} ) ? 
                $map_type_mon{$self->{results}->{$oid_ciscoEnvMonPresent}->{$oid_ciscoEnvMonPresent . '.0'}} : 'unknown'
        )
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

1;

__END__

=head1 MODE

Check environment (Power Supplies, Fans, Temperatures, Voltages, Modules, Physical Entities).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan', 'psu', 'temperature', 'voltage', 'module', 'physical', 'sensor'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=psu)
Can also exclude specific instance: --filter=fan,1

=item B<--add-name-instance>

Add literal description for instance value (used in filter, absent-problem and threshold options).

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=fan,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='fan,CRITICAL,^(?!(up|normal)$)'

=item B<--warning>

Set warning threshold for temperatures, voltages, sensors (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for temperatures, voltages, sensors (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut
