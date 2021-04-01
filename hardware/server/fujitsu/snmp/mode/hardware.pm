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

package hardware::server::fujitsu::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|fan|voltage|power)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {        
        memory => [
            ['unknown', 'UNKNOWN'],
            ['not-present|not-available', 'OK'],
            ['ok', 'OK'],
            ['disabled', 'OK'],
            ['error', 'CRITICAL'],
            ['prefailure-predicted|prefailure-warning', 'WARNING'],
            ['fail', 'CRITICAL'], # can be failed
            ['disabled', 'OK'],
            ['hot-spare', 'OK'],
            ['mirror', 'OK'],
            ['raid', 'OK'],
            ['hidden', 'OK']
        ],        
        cpu => [
            ['unknown', 'UNKNOWN'],
            ['disabled', 'OK'],
            ['ok', 'OK'],
            ['not-present', 'OK'],
            ['error', 'CRITICAL'],
            ['prefailure-warning', 'WARNING'],
            ['fail', 'CRITICAL'], # can be failed also
            ['missing-termination', 'WARNING']
        ],        
        voltage => [
            ['unknown', 'UNKNOWN'],
            ['not-available', 'OK'],
            ['ok', 'OK'],
            ['too-low', 'WARNING'],
            ['too-high', 'WARNING'],
            ['out-of-range', 'CRITICAL'],
            ['battery-prefailure', 'CRITICAL'],
            ['warning', 'WARNING']
        ],        
        fan => [
            ['unknown', 'UNKNOWN'],
            ['disabled', 'OK'],
            ['ok', 'OK'],
            ['prefailure-predicted', 'WARNING'],
            ['fail', 'CRITICAL'],
            ['redundant-fan-failed', 'WARNING'],
            ['not-manageable', 'OK'],
            ['not-present', 'OK'],
        ],        
        temperature => [
            ['unknown', 'UNKNOWN'],
            ['sensor-disabled', 'OK'],
            ['ok', 'OK'],
            ['sensor-fail', 'CRITICAL'], # can be also sensor-failed
            ['warning-temp-warm', 'WARNING'],
            ['warning-temp-cold', 'WARNING'],
            ['critical-temp-warm', 'CRITICAL'],
            ['critical-temp-cold', 'CRITICAL'],
            ['damage-temp-warm', 'WARNING'],
            ['damage-temp-cold', 'CRITICAL'],
            ['not-available', 'OK'],
            ['temperature-warning', 'WARNING'], # can be also temperature-warning-toohot
            ['temperature-critical-toohot', 'CRITICAL'],
            ['temperature-normal', 'OK']         
        ],        
        psu => [
            ['unknown', 'UNKNOWN'],
            ['not-present', 'OK'],
            ['ok', 'OK'],
            ['ac-fail', 'CRITICAL'],
            ['dc-fail', 'CRITICAL'],
            ['failed', 'CRITICAL'],
            ['critical-temperature', 'CRITICAL'],
            ['not-manageable', 'OK'],
            ['fan-failure-predicted', 'WARNING'],
            ['fan-failure', 'CRITICAL'],
            ['power-safe-mode', 'WARNING'],
            ['non-redundant-dc-fail', 'WARNING'],
            ['non-redundant-ac-fail', 'WARNING'],
            
            ['degraded', 'WARNING'],
            ['critical', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'hardware::server::fujitsu::snmp::mode::components';
    $self->{components_module} = ['fan', 'voltage', 'psu', 'memory', 'cpu', 'temperature'];
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

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'temperature', 'fan', 'psu', 'voltage', 'cpu', 'memory'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=temperature)
Can also exclude specific instance: --filter=temperature,1

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping)
Can be specific or global: --absent-problem="fan,1.1"

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,^(?!(ok)$)'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut
