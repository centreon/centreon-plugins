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

package storage::synology::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

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
            ['Crashed', 'CRITICAL']
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
    $self->{components_module} = ['psu', 'fan', 'disk', 'raid', 'system'];

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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware (SYNOLOGY-SYSTEM-MIB, SYNOLOGY-RAID-MIB) (Fans, Power Supplies, Disk status, Raid status, System status).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'psu', 'fan', 'disk', 'raid', 'system'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=psu)
Can also exclude specific instance: --filter=psu,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,^(?!(on)$)'

=back

=cut
