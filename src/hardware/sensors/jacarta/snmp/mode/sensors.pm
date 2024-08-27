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

package hardware::sensors::jacarta::snmp::mode::sensors;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|humidity)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        default => [        
            ['unknown', 'UNKNOWN'],
            ['disable', 'OK'],
            ['normal', 'OK'],
            ['below-low-warning', 'WARNING'],
            ['below-low-critical', 'CRITICAL'],
            ['above-high-warning', 'WARNING'],
            ['above-high-critical', 'CRITICAL'],
            ['sensorError', 'CRITICAL']
        ],
        input => [
            ['normal', 'OK'],
            ['triggered', 'CRITICAL']
        ]
    };

    $self->{components_path} = 'hardware::sensors::jacarta::snmp::mode::components';
    $self->{components_module} = ['temperature', 'humidity', 'input'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    my $oid_inSeptTempUnit = '.1.3.6.1.4.1.19011.1.3.1.1.2.16.0'; # inSeptConfigTemperatureUnit
    my $oid_inSeptProTempUnit = '.1.3.6.1.4.1.19011.1.3.2.1.2.16.0'; # isConfigTemperatureUnit
    my $result = $self->{snmp}->get_leef(oids => [$oid_inSeptTempUnit, $oid_inSeptProTempUnit]);

    $self->{inSept} = 0;
    $self->{inSeptPro} = 0;
    if (defined($result->{$oid_inSeptProTempUnit})) {
        $self->{inSeptPro} = 1;
        $self->{temperature_unit} = $result->{$oid_inSeptProTempUnit} == 1 ? 'C' : 'F';
    } elsif (defined($result->{$oid_inSeptTempUnit})) {
        $self->{inSept} = 1;
        $self->{temperature_unit} = $result->{$oid_inSeptTempUnit} == 1 ? 'C' : 'F';
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub getInSeptDevices {
    my ($self, %options) = @_;

    return $self->{inSeptDevices} if (defined($self->{inSeptDevices}));

    my $oid_deviceName1 = '.1.3.6.1.4.1.19011.1.3.1.1.4.3.1.0';
    my $oid_deviceState1 = '.1.3.6.1.4.1.19011.1.3.1.1.4.3.2.0';
    my $oid_deviceName2 = '.1.3.6.1.4.1.19011.1.3.1.1.4.4.1.0';
    my $oid_deviceState2 = '.1.3.6.1.4.1.19011.1.3.1.1.4.4.2.0';
    my $result = $self->{snmp}->get_leef(oids => [
        $oid_deviceName1, $oid_deviceState1,
        $oid_deviceName2, $oid_deviceState2   
    ]);

    $self->{inSeptDevices} = {
        1 => { name => $result->{$oid_deviceName1}, state => $result->{$oid_deviceState1} == 1 ? 'disabled' : 'auto' },
        2 => { name => $result->{$oid_deviceName2}, state => $result->{$oid_deviceState2} == 1 ? 'disabled' : 'auto' }
    };

    return $self->{inSeptDevices};
}

1;

__END__

=head1 MODE

Check sensors.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'temperature', 'humidity', 'input'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=temperature --filter=input).
You can also exclude items from specific instances: --filter=temperature,1

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='temperature,CRITICAL,^(?!(normal)$)'

=item B<--warning>

Set warning threshold for 'temperature', 'humidity' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for 'temperature', 'humidity' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,50'

=back

=cut
