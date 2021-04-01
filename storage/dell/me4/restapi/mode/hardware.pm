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

package storage::dell::me4::restapi::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(fan|disk|sensor)$';

    $self->{cb_hook1} = 'init_custom';
        
    $self->{thresholds} = {
        controller => [
            ['OK', 'OK'],
            ['Operational', 'OK'],
            ['Redundant', 'OK'],
            ['Redundant with independent cache', 'OK'],
            ['Degraded', 'WARNING'],
            ['Operational but not redundant', 'WARNING'],
            ['Fault', 'CRITICAL'],
            ['Down', 'CRITICAL'],
            ['N/A', 'UNKNOWN'],
            ['Unknown', 'UNKNOWN'],
            ['Not Installed', 'UNKNOWN'],
        ],
        disk => [
            ['OK', 'OK'],
            ['Up', 'OK'],
            ['AVAIL', 'OK'],
            ['LINEAR POOL', 'OK'],
            ['LINEAR POOLVRSC', 'OK'],
            ['DEDICATED SP', 'OK'],
            ['GLOBAL SP', 'OK'],
            ['LEFTOVR', 'OK'],
            ['VDISK', 'OK'],
            ['VDISK SP', 'OK'],
            ['VIRTUAL POOL', 'OK'],
            ['Degraded', 'WARNING'],
            ['Warning', 'WARNING'],
            ['Unsupported', 'WARNING'],
            ['Fault', 'CRITICAL'],
            ['Spun Down', 'CRITICAL'],
            ['Error', 'CRITICAL'],
            ['Unrecoverable', 'CRITICAL'],
            ['Unavailable', 'CRITICAL'],
            ['FAILED', 'CRITICAL'],
            ['UNUSABLE', 'CRITICAL'],
            ['N/A', 'UNKNOWN'],
            ['Unknown', 'UNKNOWN'],
            ['Not Present', 'UNKNOWN'],
        ],
        fan => [
            ['OK', 'OK'],
            ['Up', 'OK'],
            ['Degraded', 'WARNING'],
            ['Error', 'CRITICAL'],
            ['Fault', 'CRITICAL'],
            ['Missing', 'UNKNOWN'],
            ['Off', 'UNKNOWN'],
            ['N/A', 'UNKNOWN'],
            ['Unknown', 'UNKNOWN'],
        ],
        fru => [
            ['OK', 'OK'],
            ['Fault', 'CRITICAL'],
            ['Invalid Data', 'CRITICAL'],
            ['Power OFF', 'UNKNOWN'],
            ['Absent', 'UNKNOWN'],
        ],
        psu => [
            ['OK', 'OK'],
            ['Up', 'OK'],
            ['Degraded', 'WARNING'],
            ['Error', 'CRITICAL'],
            ['Fault', 'CRITICAL'],
            ['Missing', 'UNKNOWN'],
            ['Off', 'UNKNOWN'],
            ['N/A', 'UNKNOWN'],
            ['Unknown', 'UNKNOWN'],
        ],
        sensor => [
            ['OK', 'OK'],
            ['Warning', 'WARNING'],
            ['Critical', 'CRITICAL'],
            ['Unavailable', 'CRITICAL'],
            ['Unrecoverable', 'UNKNOWN'],
            ['Not Installed', 'UNKNOWN'],
            ['Unsupported', 'UNKNOWN'],
            ['Unknown', 'UNKNOWN'],
        ],
        volume => [
            ['OK', 'OK'],
            ['Degraded', 'WARNING'],
            ['Fault', 'CRITICAL'],
            ['N/A', 'UNKNOWN'],
            ['Unknown', 'UNKNOWN'],
        ],
    };
    
    $self->{components_path} = 'storage::dell::me4::restapi::mode::components';
    $self->{components_module} = ['controller', 'disk', 'fan', 'fru', 'psu', 'sensor', 'volume'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub init_custom {
    my ($self, %options) = @_;

    $self->{custom} = $options{custom};
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'controller', 'disk', 'fan', 'fru', 'psu', 'sensor', 'volume'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter='sensor,Overall Sensor'

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='controller,OK,Operational but not redundant'

=item B<--warning>

Set warning threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut
