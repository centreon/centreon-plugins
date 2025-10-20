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

package hardware::server::dell::idrac::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:temperature|voltage|amperage|coolingdevice)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        'default.state' => [
            ['unknown', 'UNKNOWN'],
            ['enabled', 'OK'],
            ['notReady', 'WARNING'],
            ['enabledAndNotReady', 'WARNING']
        ],
        'default.status' => [
            ['other', 'UNKNOWN'],
            ['unknown', 'UNKNOWN'],
            ['ok', 'OK'],
            ['nonCritical', 'WARNING'],
            ['critical', 'CRITICAL'],
            ['nonRecoverable', 'CRITICAL']
        ],
        'probe.status' => [
            ['other', 'UNKNOWN'],
            ['unknown', 'UNKNOWN'],
            ['ok', 'OK'],
            ['nonCriticalUpper', 'WARNING'],
            ['criticalUpper', 'CRITICAL'],
            ['nonRecoverableUpper', 'CRITICAL'],
            ['nonCriticalLower', 'WARNING'],
            ['criticalLower', 'CRITICAL'],
            ['nonRecoverableLower', 'CRITICAL'],
            ['failed', 'CRITICAL']
        ],
        'pdisk.state' => [
            ['unknown', 'UNKNOWN'],
            ['readySpareDedicated', 'OK'],
            ['readySpareGlobal', 'OK'],
            ['ready', 'OK'],
            ['online', 'OK'],
            ['foreign', 'OK'],
            ['offline', 'WARNING'],
            ['blocked', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['non-raid', 'OK'],
            ['removed', 'OK'],
            ['readonly', 'WARNING']
        ],
        'enclosure.state' => [
            ['unknown', 'UNKNOWN'],
            ['ready', 'OK'],
            ['failed', 'CRITICAL'],
            ['missing', 'WARNING'],
            ['degraded', 'WARNING']
        ],
        'pdisk.smartalert' => [
            ['off', 'OK'],
            ['on', 'WARNING']
        ],
        'vdisk.state' => [
            ['unknown', 'UNKNOWN'],
            ['online', 'OK'],
            ['failed', 'CRITICAL'],
            ['degraded', 'WARNING']
        ]
    };

    $self->{components_path} = 'hardware::server::dell::idrac::snmp::mode::components';
    $self->{components_module} = [
        'amperage', 'coolingdevice', 'coolingunit', 'enclosure', 'health', 
        'fru', 'memory', 'network', 'pci', 'pdisk',
        'processor', 'psu', 'punit', 'slot', 'storagebattery',
        'storagectrl', 'systembattery', 'temperature', 'voltage', 'vdisk'
    ];
}

my $oid_chassisName = '.1.3.6.1.4.1.674.10892.5.4.300.10.1.7';

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    push @{$self->{request}}, { oid => $oid_chassisName };
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub get_chassis_name {
    my ($self, %options) = @_;

    my $name = 'unknown';
    if (defined($self->{results}->{$oid_chassisName}->{ $oid_chassisName . '.' . $options{id} })) {
        $name = $self->{results}->{$oid_chassisName}->{ $oid_chassisName . '.' . $options{id} }
    }

    return $name;
}

sub get_chassis_instances {
    my ($self, %options) = @_;

    my $instances = [];
    foreach (keys %{$self->{results}->{$oid_chassisName}}) {
        /\.(\d+)$/;
        push @$instances, $1;
    }

    return $instances;
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

Check hardware components.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'amperage', 'coolingdevice', 'coolingunit', 'enclosure', 
'health', 'fru', 'memory', 'network', 'pci', 'pdisk', 
'processor', 'psu', 'punit', 'slot', 'storagebattery', 
'storagectrl', 'systembattery', 'temperature', 'voltage', 'vdisk'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=temperature --filter=psu).
You can also exclude items from specific instances: --filter=temperature,1.1

=item B<--absent-problem>

Return an error if a component is not 'present' (default is skipping).
It can be set globally or for a specific instance: --absent-problem='component_name' or --absent-problem='component_name,instance_value'.

=item B<--add-name-instance>

Add literal description for instance value (used in filter and threshold options).

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='temperature.state,CRITICAL,^(?!(enabled)$)'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=item B<--warning-count-*>

Define the warning threshold for the number of components of one type (replace '*' with the component type).

=item B<--critical-count-*>

Define the critical threshold for the number of components of one type (replace '*' with the component type).

=back

=cut
