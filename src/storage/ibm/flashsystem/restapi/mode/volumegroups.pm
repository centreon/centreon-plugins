#
# Copyright 2026 Centreon (http://www.centreon.com/)
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
# Authors : Valentin MAROT <contact@valentin-marot.fr>
#

#
# Volume groups - the per-object granularity that makes sense on these systems.
#
# A volume only carries a status, identical across hundreds of them. A group
# carries a backup state, a last backup time, a restore in progress and the
# policies attached to it. And its names are business names: Volume_Group_ESXi,
# Volume_Group_DB01 - readable on call.
#
# A group without a policy is not an anomaly in itself: it is an operational
# decision. The mode therefore exposes it as a metric and lets --warning-status
# decide, rather than imposing a judgement.
#

package storage::ibm::flashsystem::restapi::mode::volumegroups;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_group_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        '%s volume(s), backup: %s',
        $self->{result_values}->{volume_count},
        $self->{result_values}->{backup_status}
    );

    $msg .= sprintf(', last backup: %s', $self->{result_values}->{last_backup_time})
        if ($self->{result_values}->{last_backup_time} ne '-');
    $msg .= sprintf(', partition: %s', $self->{result_values}->{partition_name})
        if ($self->{result_values}->{partition_name} ne '-');
    $msg .= sprintf(', replication: %s', $self->{result_values}->{replication_policy})
        if ($self->{result_values}->{replication_policy} ne '-');
    $msg .= sprintf(', snapshot policy: %s', $self->{result_values}->{snapshot_policy})
        if ($self->{result_values}->{snapshot_policy} ne '-');
    $msg .= ', restore in progress'
        if ($self->{result_values}->{restore_in_progress} =~ /^yes$/i);

    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Volume groups: ';
}

sub prefix_group_output {
    my ($self, %options) = @_;

    return "Volume group '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'groups', type => 1, cb_prefix_output => 'prefix_group_output',
          message_multiple => 'All volume groups are healthy', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'detected', nlabel => 'volumegroups.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => '%s detected',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'replicated', nlabel => 'volumegroups.replicated.count', set => {
                key_values => [ { name => 'replicated' } ],
                output_template => '%s replicated',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'without-snapshot-policy', nlabel => 'volumegroups.without.snapshot.policy.count', set => {
                key_values => [ { name => 'without_snapshot_policy' } ],
                output_template => '%s without a snapshot policy',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'restoring', nlabel => 'volumegroups.restoring.count', set => {
                key_values => [ { name => 'restoring' } ],
                output_template => '%s restoring',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    # Nothing is critical by default: on the arrays surveyed backup_status was
    # 'off' everywhere, which is an operational choice and not a failure. The
    # threshold is set once the backup policy is decided, not before.
    $self->{maps_counters}->{groups} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{backup_status} =~ /^failed$/i',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'volume_count' }, { name => 'backup_status' },
                    { name => 'last_backup_time' }, { name => 'partition_name' },
                    { name => 'replication_policy' }, { name => 'snapshot_policy' },
                    { name => 'safeguarded_policy' }, { name => 'restore_in_progress' }
                ],
                closure_custom_output => $self->can('custom_group_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'      => { name => 'filter_name' },
        'filter-partition:s' => { name => 'filter_partition' }
    });

    return $self;
}

sub field {
    my ($entry, $name) = @_;

    return '-' if (!defined($entry->{$name}) || $entry->{$name} eq '');
    return $entry->{$name};
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        detected => 0, replicated => 0, without_snapshot_policy => 0, restoring => 0
    };
    $self->{groups} = {};

    foreach my $group (@{ $options{custom}->request(command => 'lsvolumegroup') }) {
        my $name = field($group, 'name');
        my $partition = field($group, 'partition_name');

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $name !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_partition}) && $self->{option_results}->{filter_partition} ne ''
            && $partition !~ /$self->{option_results}->{filter_partition}/);

        # The replication policy is read either directly, or through the HA
        # policy when the system is in 2-site-ha: both fields coexist and only
        # one is set depending on the topology.
        my $replication = field($group, 'replication_policy_name');
        $replication = field($group, 'ha_replication_policy_name') if ($replication eq '-');

        my $snapshot = field($group, 'snapshot_policy_name');
        my $restore = field($group, 'restore_in_progress');

        $self->{global}->{detected}++;
        $self->{global}->{replicated}++ if ($replication ne '-');
        $self->{global}->{without_snapshot_policy}++ if ($snapshot eq '-');
        $self->{global}->{restoring}++ if ($restore =~ /^yes$/i);

        $self->{groups}->{$name} = {
            name => $name,
            volume_count => field($group, 'volume_count'),
            backup_status => field($group, 'backup_status'),
            last_backup_time => field($group, 'last_backup_time'),
            partition_name => $partition,
            replication_policy => $replication,
            snapshot_policy => $snapshot,
            safeguarded_policy => field($group, 'safeguarded_policy_name'),
            restore_in_progress => $restore
        };
    }
}

1;

__END__

=head1 MODE

Check the volume groups — the per-object granularity that means something on
these arrays.

A volume carries only a status, identical across all 349 of them. A group
carries a backup state, a last backup time, a restore in progress and the
policies attached to it. And its name is a business one — C<Volume_Group_ESXi>,
C<Volume_Group_DBWMSPRTRI01> — which reads well on call.

Example, one service per group through service discovery:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=volume-groups --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx --insecure \
        --filter-name='^Volume_Group_ESXi$'

=over 8

=item B<--filter-name> B<--filter-partition>

Only check groups whose name or storage partition matches this regular
expression. Empty by default.

=item B<--unknown-status> B<--warning-status> B<--critical-status>

Threshold on each group. Available macros: C<name>, C<volume_count>,
C<backup_status>, C<last_backup_time>, C<partition_name>,
C<replication_policy>, C<snapshot_policy>, C<safeguarded_policy>,
C<restore_in_progress>.

Default critical: C<%{backup_status} =~ /^failed$/i>

Nothing else alerts by default. On these arrays C<backup_status> is C<off>
everywhere and no group references a snapshot policy — an operational choice,
not a fault. Once that choice is settled, express it here rather than in the
code:

    --warning-status='%{snapshot_policy} eq "-"'

=item B<--warning-without-snapshot-policy> B<--critical-without-snapshot-policy>

Threshold on the number of groups with no snapshot policy attached. The blunt
version of the same question, when the answer is "all of them should have one".

=item B<--warning-replicated> B<--critical-replicated> B<--warning-restoring> B<--critical-restoring>

Thresholds on the counts.

=back

=cut
