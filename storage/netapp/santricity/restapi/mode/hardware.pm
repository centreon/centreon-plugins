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

package storage::netapp::santricity::restapi::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:drive.temperature)$';

    $self->{cb_hook2} = 'execute_custom';

    $self->{thresholds} = {
        battery => [
            ['optimal', 'OK'],
            ['fullCharging', 'OK'],
            ['nearExpiration', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['removed', 'OK'],
            ['unknown', 'UNKNOWN'],
            ['notInConfig', 'WARNING'],
            ['configMismatch', 'WARNING'],
            ['learning', 'OK'],
            ['overtemp', ''],
            ['expired', 'WARNING'],
            ['maintenanceCharging', 'OK'],
            ['replacementRequired', 'CRITICAL']
        ],
        board => [
            ['unknown', 'UNKNOWN'],
            ['optimal', 'OK'],
            ['needsAttention', 'WARNING'],
            ['notPresent', 'OK'],
            ['degraded', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['diagInProgress', 'OK']
        ],
        cbd => [
            ['unknown', 'UNKNOWN'],
            ['optimal', 'OK'],
            ['failed', 'CRITICAL'],
            ['removed', 'OK'],
            ['writeProtected', 'OK'],
            ['incompatible', 'CRITICAL']
        ],
        cmd => [
            ['unknown', 'UNKNOWN'],
            ['optimal', 'OK'],
            ['failed', 'CRITICAL'],
            ['empty', 'OK']
        ],
        ctrl => [
            ['unknown', 'UNKNOWN'],
            ['optimal', 'OK'],
            ['failed', 'CRITICAL'],
            ['removed', 'OK'],
            ['rpaParErr', 'WARNING'],
            ['serviceMode', 'OK'],
            ['suspended', 'OK'],
            ['degraded', 'WARNING']
        ],
        drive => [
            ['optimal', 'OK'],
            ['failed', 'CRITICAL'],
            ['replaced', 'OK'],
            ['bypassed', 'OK'],
            ['unresponsive', 'WARNING'],
            ['removed', 'OK'],
            ['incompatible', 'WARNING'],
            ['dataRelocation', 'OK'],
            ['preFailCopy', 'WARNING'],
            ['preFailCopyPending', 'WARNING']
        ],
        fan => [
            ['optimal', 'OK'],
            ['removed', 'OK'],
            ['failed', 'CRITICAL'],
            ['unknown', 'UNKNOWN']
        ],
        psu => [
            ['optimal', 'OK'],
            ['removed', 'OK'],
            ['failed', 'CRITICAL'],
            ['unknown', 'UNKNOWN'],
            ['noinput', 'WARNING']
        ],
        storage => [
            ['neverContacted', 'UNKNOWN'],
            ['offline', 'OK'],
            ['optimal', 'OK'],
            ['needsAttn', 'WARNING'],
            ['newDevice', 'OK'],
            ['lockDown', 'WARNING']
        ],
        thsensor => [
            ['optimal', 'OK'],
            ['nominalTempExceed', 'WARNING'],
            ['maxTempExceed', 'CRITICAL'],
            ['unknown', 'UNKNOWN'],
            ['removed', 'OK']
        ]
    };

    $self->{components_exec_load} = 0;

    $self->{components_path} = 'storage::netapp::santricity::restapi::mode::components';
    $self->{components_module} = [
        'storage', 'ctrl', 'battery', 'board', 'cbd', 'cmd', 'drive', 'psu', 'fan',
        'thsensor'
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub execute_custom {
    my ($self, %options) = @_;

    $self->{json_results} = $options{custom}->execute_storages_request(
        endpoints => [ { endpoint => '/hardware-inventory' } ]
    );
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'storage', 'ctrl', 'battery', 'board', 'cbd', 'cmd', 'drive', 'psu', 'fan', 'thsensor'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter='drive,010000005000C500C244251B0000000000000000'

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='drive,OK,preFailCopy'

=item B<--warning>

Set warning threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --warning='drive.temperature,.*,40'

=item B<--critical>

Set critical threshold for 'drive.temperature' (syntax: type,regexp,threshold)
Example: --critical='drive.temperature,.*,50'

=back

=cut
