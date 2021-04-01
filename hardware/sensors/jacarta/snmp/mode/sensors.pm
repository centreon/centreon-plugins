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
    my $oid_isConfigTemperatureUnit = '.1.3.6.1.4.1.19011.1.3.2.1.2.16'; # .0
    push @{$self->{request}}, { oid => $oid_isConfigTemperatureUnit };
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
    
    $self->{temperature_unit} = defined($self->{results}->{$oid_isConfigTemperatureUnit}->{$oid_isConfigTemperatureUnit . '.0'}) && $self->{results}->{$oid_isConfigTemperatureUnit}->{$oid_isConfigTemperatureUnit . '.0'} == 1 ?
       'C' : 'F';
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

Check sensors.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'temperature', 'humidity', 'input'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=temperature --filter=input)
Can also exclude specific instance: --filter=temperature,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='temperature,CRITICAL,^(?!(normal)$)'

=item B<--warning>

Set warning threshold for 'temperature', 'humidity' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for 'temperature', 'humidity' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,50'

=back

=cut
