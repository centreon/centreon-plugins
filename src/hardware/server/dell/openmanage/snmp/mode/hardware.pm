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

package hardware::server::dell::openmanage::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|fan|psu\.power)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['other', 'CRITICAL'],
            ['unknown', 'UNKNOWN'],
            ['ok', 'OK'],
            ['nonCritical', 'WARNING'], # nonCriticalUpper # nonCriticalLower
            ['critical', 'CRITICAL'], # criticalUpper
            ['nonRecoverable', 'CRITICAL'], # nonRecoverableUpper # nonRecoverableLower
            ['failed', 'CRITICAL']
        ],
        physicaldisk_smartalert => [
            ['yes', 'WARNING'],
            ['no', 'OK']
        ]
    };
    
    $self->{components_path} = 'hardware::server::dell::openmanage::snmp::mode::components';
    $self->{components_module} = [
        'globalstatus', 'fan', 'psu', 'temperature', 'cpu', 'cachebattery', 'memory',
        'physicaldisk', 'logicaldrive', 'esmlog', 'battery', 'controller', 'connector'
    ];
}

sub snmp_execute {
    my ($self, %options) = @_;

    # In '10892-MIB'
    my $oid_chassisModelName = '.1.3.6.1.4.1.674.10892.1.300.10.1.9';

    $self->{snmp} = $options{snmp};
    push @{$self->{request}}, { oid => $oid_chassisModelName };
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
    
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_chassisModelName}})) {
        my $name = defined($self->{results}->{$oid_chassisModelName}->{$oid}) ? 
            centreon::plugins::misc::trim($self->{results}->{$oid_chassisModelName}->{$oid}) : 'unknown';
        $self->{output}->output_add(long_msg => sprintf("Product Name: %s", $name));
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check Hardware (Global status, Fans, CPUs, Power Supplies, Temperature, Storage).

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'globalstatus', 'fan', 'cpu', 'psu', 'temperature', 'cachebattery',
'physicaldisk', 'logicaldrive', 'battery', 'controller', 'connector'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=fan).
You can also exclude items from specific instances: --filter=fan,1

=item B<--absent-problem>

Return an error if a component is not 'present' (default is skipping).
It can be set globally or for a specific instance: --absent-problem='component_name' or --absent-problem='component_name,instance_value'.

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,status,regexp).
Example: --threshold-overload='temperature,CRITICAL,^(?!(ok)$)'

=item B<--warning>

Set warning threshold for temperature, psu.power or fan (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for temperature, psu.power or fan (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=item B<--warning-count-*>

Define the warning threshold for the number of components of one type (replace '*' with the component type).

=item B<--critical-count-*>

Define the critical threshold for the number of components of one type (replace '*' with the component type).

=back

=cut
    
