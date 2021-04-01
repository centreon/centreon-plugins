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

package hardware::server::ibm::bladecenter::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_numeric_check_section_option} = '^(blower|ambient|fanpack|chassisfan)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        chassisstatus => [
            ['testSucceeded', 'OK'],
            ['testFailed', 'CRITICAL'],
        ],
        systemhealth => [
            ['normal', 'OK'],
            ['systemLevel', 'WARNING'],
            ['nonCritical', 'WARNING'],
            ['critical', 'CRITICAL'],
        ],
        powermodule => [
            ['unknown', 'UNKNOWN'],
            ['good', 'OK'],
            ['warning', 'WARNING'],
            ['notAvailable', 'UNKNOWN'],
        ],
        fanpack => [
            ['unknown', 'UNKNOWN'],
            ['good', 'OK'],
            ['warning', 'WARNING'],
            ['bad', 'CRITICAL'],
        ],
        chassisfan => [
            ['unknown', 'UNKNOWN'],
            ['good', 'OK'],
            ['warning', 'WARNING'],
            ['bad', 'CRITICAL'],
        ],    
        blower => [
            ['unknown', 'UNKNOWN'],
            ['good', 'OK'],
            ['warning', 'WARNING'],
            ['bad', 'CRITICAL'],
        ],
        switchmodule => [
            ['unknown', 'UNKNOWN'],
            ['good', 'OK'],
            ['warning', 'WARNING'],
            ['bad', 'CRITICAL'],
        ],
        blowerctrl => [
            ['unknown', 'UNKNOWN'],
            ['operational', 'OK'],
            ['flashing', 'WARNING'],
            ['communicationError', 'CRITICAL'],
            ['notPresent', 'UNKNOWN'],
        ],
        blade => [
            ['unknown', 'UNKNOWN'],
            ['good', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
            ['kernelMode', 'WARNING'],
            ['discovering', 'WARNING'],
            ['commError', 'CRITICAL'],
            ['noPower', 'WARNING'],
            ['flashing', 'WARNING'],
            ['initFailure', 'CRITICAL'],
            ['insufficientPower', 'CRITICAL'],
            ['powerDenied', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'hardware::server::ibm::bladecenter::snmp::mode::components';
    $self->{components_module} = ['ambient', 'powermodule', 'blade', 'blower', 'fanpack', 'chassisfan', 'systemhealth', 'chassisstatus', 'switchmodule'];
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
    
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

1;

__END__

=head1 MODE

Check Hardware (Ambient temperatures, Blowers, Power modules, Blades, System Health, Chassis status, Fanpack).

=over 8

=item B<--component>

Which component to check (Default: 'all').
Can be: 'ambient', 'powermodule', 'fanpack', 'chassisfan', 
'blower', 'blade', 'systemhealth', 'chassisstatus', 'switchmodule'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=blower --filter=powermodule)
Can also exclude specific instance: --filter=blower,1

=item B<--absent-problem>

Return an error if an entity is not 'notAvailable' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=powermodule,2

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='blade,OK,unknown'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='ambient,mm,30' --warning='ambient,frontpanel,35' 

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='blower,1,50'

=back

=cut