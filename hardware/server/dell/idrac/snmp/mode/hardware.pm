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
            ['ready', 'WARNING'],
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
        'amperage', 'coolingdevice', 'coolingunit', 'enclosure',
        'fru', 'memory', 'network', 'pci', 'pdisk',
        'processor', 'psu', 'punit', 'slot', 'storagebattery',
        'storagectrl', 'systembattery', 'temperature', 'voltage', 'vdisk'
    ];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
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

Check hardware components.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'amperage', 'coolingdevice', 'coolingunit', 'enclosure', 
'fru', 'memory', 'network', 'pci', 'pdisk', 
'processor', 'psu', 'punit', 'slot', 'storagebattery', 
'storagectrl', 'systembattery', 'temperature', 'voltage', 'vdisk'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=temperature --filter=psu)
Can also exclude specific instance: --filter=temperature,1.1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='temperature.state,CRITICAL,^(?!(enabled)$)'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut
    
