#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::ibm::flashsystem::restapi::mode::volumegroups;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_empty is_excluded is_not_empty);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_group_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        '%s volume(s), backup: %s',
        $self->{result_values}->{volume_count},
        $self->{result_values}->{backup_status}
    );

    $msg .= sprintf(', last backup: %s', $self->{result_values}->{last_backup_time})
        if (is_not_empty($self->{result_values}->{last_backup_time}));
    $msg .= sprintf(', partition: %s', $self->{result_values}->{partition_name})
        if (is_not_empty($self->{result_values}->{partition_name}));
    $msg .= sprintf(', replication: %s', $self->{result_values}->{replication_policy})
        if (is_not_empty($self->{result_values}->{replication_policy}));
    $msg .= sprintf(', snapshot policy: %s', $self->{result_values}->{snapshot_policy})
        if (is_not_empty($self->{result_values}->{snapshot_policy}));
    $msg .= ', restore in progress'
        if ($self->{result_values}->{restore_in_progress} =~ /^yes$/i);

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Volume groups: ' },
        { name => 'groups', type => COUNTER_TYPE_INSTANCE, prefix_output => "Volume group '%{name}' ",
          message_multiple => 'All volume groups are healthy', skipped_code => { NO_VALUE() => 1 } }
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
        { label => 'without-snapshot-policy', nlabel => 'volumegroups.without.snapshot.policy.count', display_ok => 0, set => {
                key_values => [ { name => 'without_snapshot_policy' } ],
                output_template => '%s without a snapshot policy',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'restoring', nlabel => 'volumegroups.restoring.count', display_ok => 0, set => {
                key_values => [ { name => 'restoring' } ],
                output_template => '%s restoring',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{groups} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
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
        'include-name:s'      => { name => 'include_name' },
        'exclude-name:s'      => { name => 'exclude_name' },
        'include-partition:s' => { name => 'include_partition' },
        'exclude-partition:s' => { name => 'exclude_partition' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { detected => 0, replicated => 0, without_snapshot_policy => 0, restoring => 0 };
    $self->{groups} = {};

    foreach my $group (@{$options{custom}->request(command => 'lsvolumegroup')}) {
        my $name = $group->{name} // '';
        my $partition = $group->{partition_name} // '';

        next if (is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}));
        next if (is_excluded($partition, $self->{option_results}->{include_partition}, $self->{option_results}->{exclude_partition}));

        # In 2-site-ha, the replication policy is carried by the HA policy field.
        my $replication = is_not_empty($group->{replication_policy_name})
            ? $group->{replication_policy_name}
            : $group->{ha_replication_policy_name} // '';
        my $snapshot = $group->{snapshot_policy_name} // '';
        my $restore = $group->{restore_in_progress} // '';

        $self->{global}->{detected}++;
        $self->{global}->{replicated}++ if (is_not_empty($replication));
        $self->{global}->{without_snapshot_policy}++ if (is_empty($snapshot));
        $self->{global}->{restoring}++ if ($restore =~ /^yes$/i);

        $self->{groups}->{$name} = {
            name => $name,
            volume_count => $group->{volume_count} // '',
            backup_status => $group->{backup_status} // '',
            last_backup_time => $group->{last_backup_time} // '',
            partition_name => $partition,
            replication_policy => $replication,
            snapshot_policy => $snapshot,
            safeguarded_policy => $group->{safeguarded_policy_name} // '',
            restore_in_progress => $restore
        };
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'partition_name', 'volume_count', 'replication_policy']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $name (sort keys %{$self->{groups}}) {
        $self->{output}->add_disco_entry(
            name => $self->{groups}->{$name}->{name},
            partition_name => $self->{groups}->{$name}->{partition_name},
            volume_count => $self->{groups}->{$name}->{volume_count},
            replication_policy => $self->{groups}->{$name}->{replication_policy}
        );
    }
}

1;

__END__

=head1 MODE

Check volume groups.

This mode also supports service discovery (C<--disco-format>, C<--disco-show>).

=over 8

=item B<--include-name>

Filter volume groups by name (can be a regexp).

=item B<--exclude-name>

Exclude volume groups by name (can be a regexp).

=item B<--include-partition>

Filter volume groups by storage partition name (can be a regexp).

=item B<--exclude-partition>

Exclude volume groups by storage partition name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{name}>, C<%{volume_count}>, C<%{backup_status}>, C<%{last_backup_time}>, C<%{partition_name}>, C<%{replication_policy}>, C<%{snapshot_policy}>, C<%{safeguarded_policy}>, C<%{restore_in_progress}>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{backup_status} =~ /^failed$/i'>).
You can use the following variables: C<%{name}>, C<%{volume_count}>, C<%{backup_status}>, C<%{last_backup_time}>, C<%{partition_name}>, C<%{replication_policy}>, C<%{snapshot_policy}>, C<%{safeguarded_policy}>, C<%{restore_in_progress}>

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{volume_count}>, C<%{backup_status}>, C<%{last_backup_time}>, C<%{partition_name}>, C<%{replication_policy}>, C<%{snapshot_policy}>, C<%{safeguarded_policy}>, C<%{restore_in_progress}>

=item B<--warning-detected>

Threshold.

=item B<--critical-detected>

Threshold.

=item B<--warning-replicated>

Threshold.

=item B<--critical-replicated>

Threshold.

=item B<--warning-without-snapshot-policy>

Threshold.

=item B<--critical-without-snapshot-policy>

Threshold.

=item B<--warning-restoring>

Threshold.

=item B<--critical-restoring>

Threshold.

=back

=cut
