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

package storage::synology::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:disk.badsectors)$';

    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        # system, fan, psu
        default => [
            ['Normal', 'OK'],
            ['Failed', 'CRITICAL']
        ],
        disk => [
            ['Normal', 'OK'],
            ['Initialized', 'OK'],
            ['NotInitialized', 'OK'],
            ['SystemPartitionFailed', 'CRITICAL'],
            ['Crashed', 'CRITICAL'],

            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
            ['failing', 'CRITICAL']
        ],
        raid => [
            ['Normal', 'OK'],
            ['Repairing', 'OK'],
            ['Migrating', 'OK'],
            ['Expanding', 'OK'],
            ['Deleting', 'OK'],
            ['Creating', 'OK'],
            ['RaidSyncing', 'OK'],
            ['RaidParityChecking', 'OK'],
            ['RaidAssembling', 'OK'],
            ['Canceling', 'OK'],
            ['Degrade', 'WARNING'],
            ['Crashed', 'CRITICAL'],
            ['DataScrubbing', 'OK'],
            ['RaidDeploying', 'OK'],
            ['RaidUnDeploying', 'OK'],
            ['RaidMountCache', 'OK'],
            ['RaidUnmountCache', 'OK'],
            ['RaidExpandingUnfinishedSHR', 'OK'],
            ['RaidConvertSHRToPool', 'OK'],
            ['RaidMigrateSHR1ToSHR2', 'OK'],
            ['RaidUnknownStatus', 'UNKNOWN']
        ]
    };
    
    $self->{components_path} = 'storage::synology::snmp::mode::components';
    $self->{components_module} = ['disk', 'fan', 'psu', 'raid', 'system'];

    $self->{request_leef} = [];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    if (scalar(@{$self->{request}}) > 0) {
        $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
    }
    if (scalar(@{$self->{request_leef}}) > 0) {
        $self->{results_leef} = $self->{snmp}->get_leef(oids => $self->{request_leef});
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

Check hardware.

=over 8

=item B<--component>

Filter the components to monitor with a regular expression (default: '.*').
Available components: psu, fan, disk, raid, system.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=psu).
You can also exclude items from specific instances: --filter=psu,1

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='psu,CRITICAL,^(?!(on)$)'

=item B<--warning>

Set warning threshold for 'disk.badsectors' (syntax: type,regexp,threshold)
Example: --warning='disk.badsectors,.*,30'

=item B<--critical>

Set critical threshold for 'disk.badsectors' (syntax: type,regexp,threshold)
Example: --critical='disk.badsectors,.*,50'

=back

=cut
