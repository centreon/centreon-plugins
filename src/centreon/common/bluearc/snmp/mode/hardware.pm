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

package centreon::common::bluearc::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|fan)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        psu => [
            ['ok', 'OK'],
            ['failed', 'CRITICAL'],
            ['notFitted', 'WARNING'],
            ['unknown', 'UNKNOWN']
        ],
        'fan.speed' => [
            ['ok', 'OK'],
            ['warning', 'WARNING'],
            ['severe', 'CRITICAL'],
            ['unknown', 'UNKNOWN']
        ],
        temperature => [
            ['ok', 'OK'],
            ['tempWarning', 'WARNING'],
            ['tempSevere', 'CRITICAL'],
            ['tempSensorFailed', 'CRITICAL'],
            ['tempSensorWarning', 'CRITICAL'],
            ['unknown', 'UNKNOWN']
        ],
        sysdrive => [
            ['online', 'OK'],
            ['corrupt', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['notPresent', 'OK'],
            ['disconnected', 'WARNING'],
            ['offline', 'OK'],
            ['initializing', 'OK'],
            ['formatting', 'OK'],
            ['unknown', 'UNKNOWN']
        ],
        battery => [
            ['ok', 'OK'],
            ['fault', 'CRITICAL'],
            ['notFitted', 'WARNING'],
            ['initializing', 'OK'],
            ['normalCharging', 'OK'],
            ['discharged', 'CRITICAL'],
            ['cellTesting', 'OK'],
            ['notResponding', 'CRITICAL'],
            ['low', 'WARNING'],
            ['veryLow', 'CRITICAL'],
            ['ignore', 'UNKNOWN']
        ]
    };

    $self->{components_path} = 'centreon::common::bluearc::snmp::mode::components';
    $self->{components_module} = ['temperature', 'fan', 'psu', 'sysdrive', 'battery' ];
}

sub snmp_execute {
    my ($self, %options) = @_;

    my $oid_clusterPNodeName = '.1.3.6.1.4.1.11096.6.1.1.1.2.5.9.1.2';
    push @{$self->{request}}, { oid => $oid_clusterPNodeName };

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});

    $self->{pnodes} = {};
    foreach (keys %{$self->{results}->{$oid_clusterPNodeName}}) {
        /^$oid_clusterPNodeName\.(.*)$/;
        $self->{pnodes}->{$1} = $self->{results}->{$oid_clusterPNodeName}->{$_};
    }
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

Check Hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'temperature', 'fan', 'psu', 'sysdrive', 'battery'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=sysdrive).
You can also exclude items from specific instances: --filter=sysdrive,1

=item B<--no-component>

Define the expected status if no components are found (default: critical).


=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='sysdrive,OK,formatting'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut
