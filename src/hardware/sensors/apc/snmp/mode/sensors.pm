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

package hardware::sensors::apc::snmp::mode::sensors;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:temperature|humidity)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        default => [        
            ['normal', 'OK'],         # alarmStatus
            ['warning', 'WARNING'],   # alarmStatus
            ['critical', 'CRITICAL'], # alarmStatus
            ['ok', 'OK'],             # commStatus
            ['notInstalled', 'OK'],   # commStatus
            ['lost', 'WARNING'],      # commStatus
            ['^active', 'OK'],        # commStatus
            ['inactive', 'OK']        # commStatus
        ]
    };

    $self->{components_path} = 'hardware::sensors::apc::snmp::mode::components';
    $self->{components_module} = [
        'temperature', 'humidity', 'fluid'
    ];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{checked_module_sensors} = 0;
    $self->{checked_wireless_sensors} = 0;

    my $oid_module_name = '.1.3.6.1.4.1.318.1.1.10.4.1.2.1.2';
    my $snmp_result = $self->{snmp}->get_table(oid => $oid_module_name);
    $self->{modules_name} = {};
    foreach (keys %$snmp_result) {
        /$oid_module_name\.(.*)$/;
        $self->{modules_name}->{$1} = $snmp_result->{$_};
    }

    my $oid_emsStatusSysTempUnits = '.1.3.6.1.4.1.318.1.1.10.3.12.11.0';
    $snmp_result = $self->{snmp}->get_leef(oids => [$oid_emsStatusSysTempUnits]);
    $self->{temp_unit} = $snmp_result->{$oid_emsStatusSysTempUnits} == 1 ? 'C' : 'F';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check sensors.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'temperature', 'humidity', 'fluid'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=temperature --filter=humidity).
You can also exclude items from specific instances: --filter=temperature,1

=item B<--absent-problem>

Return an error if a component is not 'present' (default is skipping).
It can be set globally or for a specific instance: --absent-problem='component_name' or --absent-problem='component_name,instance_value'.

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='temperature,CRITICAL,^(?!(warning)$)'

=item B<--warning>

Set warning threshold for 'temperature', 'humidity' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for 'temperature', 'humidity' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,50'

=item B<--warning-count-*>

Define the warning threshold for the number of components of one type (replace '*' with the component type).

=item B<--critical-count-*>

Define the critical threshold for the number of components of one type (replace '*' with the component type).

=back

=cut
