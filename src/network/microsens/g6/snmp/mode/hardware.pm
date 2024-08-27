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

package network::microsens::g6::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:temperature)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        fan => [
            ['ok', 'OK'],
            ['unused', 'OK'],
            ['degraded', 'WARNING'],
            ['fail', 'CRITICAL'],
            ['missing', 'OK']
        ],
        psu => [
            ['ok', 'OK'],
            ['overload', 'WARNING'],
            ['inputLow', 'OK'],
            ['fuseFail', 'CRITICAL'],
            ['notApplicable', 'OK'],
            ['unmanaged', 'OK'],
            ['notInstalled', 'OK'],
        ],
        sdcard => [
            ['empty', 'OK'],
            ['inserted', 'OK'],
            ['writeProtected', 'OK'],
            ['writing', 'OK']
        ]
    };
    
    $self->{components_path} = 'network::microsens::g6::snmp::mode::components';
    $self->{components_module} = ['fan', 'psu', 'sdcard', 'temperature'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    my $map_psu_status = {
        0 => 'ok', 1 => 'overload', 2 => 'inputLow',
        3 => 'fuseFail', 4 => 'notApplicable',
        5 => 'unmanaged', 6 => 'notInstalled'
    };
    my $map_fan_status = {
        0 => 'unused', 1 => 'ok', 2 => 'degraded',
        3 => 'fail', 4 => 'missing'
    };
    my $map_sdcard_status = {
        0 => 'empty', 1 => 'inserted', 2 => 'writeProtected', 3 => 'writing'
    };
    my $mapping = {
        system_temp   => { oid => '.1.3.6.1.4.1.3181.10.6.1.30.104' }, # systemTemperature
        psu1_status   => { oid => '.1.3.6.1.4.1.3181.10.6.1.31.100', map => $map_psu_status }, # hardwarePowerSupply1Status
        psu2_status   => { oid => '.1.3.6.1.4.1.3181.10.6.1.31.101', map => $map_psu_status }, # hardwarePowerSupply2Status
        fan_status    => { oid => '.1.3.6.1.4.1.3181.10.6.1.31.103', map => $map_fan_status }, # hardwareFanStatus
        sdcard_status => { oid => '.1.3.6.1.4.1.3181.10.6.1.31.104', map => $map_sdcard_status }  # hardwareSdCardStatus
    };

    my $snmp_result = $options{snmp}->get_leef(oids => [ map($_->{oid} . '.0', values(%$mapping)) ]);
    $self->{results} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
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

Check hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'fan', 'psu', 'sdcard', 'temperature'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=fan).
You can also exclude items from specific instances: --filter=psu,2

=item B<--no-component>

Define the expected status if no components are found (default: critical).


=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='sdcard,WARNING,empty'

=item B<--warning>

Set warning threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut
