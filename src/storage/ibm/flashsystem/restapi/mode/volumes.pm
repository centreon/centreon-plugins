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
# Overall volume state.
#
# This mode is aggregated on purpose. Neither lsvdisk nor lsvdiskcopy exposes
# used_capacity in the concise view: a volume's consumption would need the
# detailed view, one call per volume - several hundred per cycle on a typical
# array. The only state really available per volume is its status, and they
# are all 'online'. One service per volume would therefore show "online" and a
# fixed size, hundreds of times.
#
# The service counts the states and NAMES the abnormal volumes in its output:
# the diagnostic granularity is kept, the hundreds of services are not. For a
# per-object monitoring, see the volume-groups mode, whose objects carry a real
# state.
#
# Two reading traps:
#   - fast_write_state = 'not_empty' is the NORMAL state of a working volume
#     (data in the write cache). Only 'corrupt' is abnormal.
#   - a volume 'full' with regard to its provisioned size means nothing with
#     thin provisioning: capacity is managed at pool level.
#

package storage::ibm::flashsystem::restapi::mode::volumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_volume_output {
    my ($self, %options) = @_;

    my $msg = sprintf('status: %s', $self->{result_values}->{status});

    $msg .= sprintf(', pool: %s', $self->{result_values}->{mdisk_grp_name})
        if ($self->{result_values}->{mdisk_grp_name} ne '-');
    $msg .= sprintf(', volume group: %s', $self->{result_values}->{volume_group_name})
        if ($self->{result_values}->{volume_group_name} ne '-');
    $msg .= sprintf(', write cache: %s', $self->{result_values}->{fast_write_state})
        if ($self->{result_values}->{fast_write_state} !~ /^(empty|not_empty)$/i);
    $msg .= ', formatting'
        if ($self->{result_values}->{formatting} =~ /^yes$/i);
    $msg .= ', copies not synchronised'
        if ($self->{result_values}->{sync} =~ /^no$/i);

    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Volumes: ';
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return "Volume '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        { name => 'volumes', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_volume_output',
          message_multiple => 'All volumes are online and synchronised', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'detected', nlabel => 'volumes.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => '%s detected',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'online', nlabel => 'volumes.online.count', set => {
                key_values => [ { name => 'online' } ],
                output_template => '%s online',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'degraded', nlabel => 'volumes.degraded.count', set => {
                key_values => [ { name => 'degraded' } ],
                output_template => '%s degraded',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'offline', nlabel => 'volumes.offline.count', set => {
                key_values => [ { name => 'offline' } ],
                output_template => '%s offline',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'unsynchronised', nlabel => 'volumes.unsynchronised.count', set => {
                key_values => [ { name => 'unsynchronised' } ],
                output_template => '%s with copies out of sync',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    # Only abnormal volumes become instances: hundreds of lines are not
    # created to say that all is well.
    $self->{maps_counters}->{volumes} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} =~ /^offline$/i || %{fast_write_state} =~ /^corrupt$/i',
            warning_default => '%{status} =~ /^degraded$/i || %{sync} =~ /^no$/i',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'status' }, { name => 'fast_write_state' },
                    { name => 'formatting' }, { name => 'sync' },
                    { name => 'mdisk_grp_name' }, { name => 'volume_group_name' }
                ],
                closure_custom_output => $self->can('custom_volume_output'),
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
        'filter-name:s'         => { name => 'filter_name' },
        'filter-pool:s'         => { name => 'filter_pool' },
        'filter-volume-group:s' => { name => 'filter_volume_group' },
        'add-all-volumes'       => { name => 'add_all_volumes' }
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

    # Copy synchronisation lives on lsvdiskcopy, not on lsvdisk: a volume can
    # be 'online' with an out-of-sync copy.
    my %unsynced;
    foreach my $copy (@{ $options{custom}->request_optional(command => 'lsvdiskcopy') }) {
        my $name = field($copy, 'vdisk_name');
        $unsynced{$name} = 1 if (field($copy, 'sync') =~ /^no$/i);
    }

    $self->{global} = {
        detected => 0, online => 0, degraded => 0, offline => 0, unsynchronised => 0
    };
    $self->{volumes} = {};

    foreach my $volume (@{ $options{custom}->request(command => 'lsvdisk') }) {
        my $name = field($volume, 'name');
        my $pool = field($volume, 'mdisk_grp_name');
        my $group = field($volume, 'volume_group_name');

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $name !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_pool}) && $self->{option_results}->{filter_pool} ne ''
            && $pool !~ /$self->{option_results}->{filter_pool}/);
        next if (defined($self->{option_results}->{filter_volume_group}) && $self->{option_results}->{filter_volume_group} ne ''
            && $group !~ /$self->{option_results}->{filter_volume_group}/);

        my $status = field($volume, 'status');
        my $fast_write = field($volume, 'fast_write_state');
        my $sync = $unsynced{$name} ? 'no' : 'yes';

        $self->{global}->{detected}++;
        $self->{global}->{online}++   if ($status =~ /^online$/i);
        $self->{global}->{degraded}++ if ($status =~ /^degraded$/i);
        $self->{global}->{offline}++  if ($status =~ /^offline$/i);
        $self->{global}->{unsynchronised}++ if ($sync eq 'no');

        my $healthy = ($status =~ /^online$/i)
            && ($fast_write !~ /^corrupt$/i)
            && ($sync eq 'yes')
            && (field($volume, 'formatting') !~ /^yes$/i);

        # By default, only abnormal volumes become instances.
        next if ($healthy && !defined($self->{option_results}->{add_all_volumes}));

        $self->{volumes}->{$name} = {
            name => $name,
            status => $status,
            fast_write_state => $fast_write,
            formatting => field($volume, 'formatting'),
            sync => $sync,
            mdisk_grp_name => $pool,
            volume_group_name => $group
        };
    }
}

1;

__END__

=head1 MODE

Check the volumes as a whole.

This mode is aggregated on purpose. Neither C<lsvdisk> nor C<lsvdiskcopy>
exposes C<used_capacity> in their concise output: a volume's consumption would
need the detailed view, one call per volume — 349 per cycle on these arrays. The
only per-volume state actually available is the status, and they are all
C<online>. One service per volume would display "online" and a frozen size,
seven hundred times over.

So the service counts the states and B<names> the abnormal volumes in its
output: the diagnostic detail is kept, the seven hundred services are not. For
per-object monitoring, use the C<volume-groups> mode, whose objects carry a real
state — replication, backup, attached policies.

Two reading traps:

=over 4

=item * C<fast_write_state = not_empty> is the B<normal> state of a working
volume — data sitting in the write cache. Only C<corrupt> is abnormal.

=item * A volume "full" with respect to its provisioned size means nothing under
thin provisioning. Capacity is managed at the pool level, see the C<capacity>
mode.

=back

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=volumes --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx --insecure

=over 8

=item B<--filter-name> B<--filter-pool> B<--filter-volume-group>

Only check volumes whose name, pool or volume group matches this regular
expression. Empty by default.

=item B<--add-all-volumes>

Turn every volume into a checkable instance, not just the abnormal ones. Use
with a filter — this is what makes a per-volume service possible if you really
want one:

    --mode=volumes --add-all-volumes --filter-name='^VOL_PRD_01$'

=item B<--unknown-status> B<--warning-status> B<--critical-status>

Threshold on each selected volume. Available macros: C<name>, C<status>,
C<fast_write_state>, C<formatting>, C<sync>, C<mdisk_grp_name>,
C<volume_group_name>.

Default warning: C<%{status} =~ /^degraded$/i || %{sync} =~ /^no$/i>

Default critical: C<%{status} =~ /^offline$/i || %{fast_write_state} =~ /^corrupt$/i>

=item B<--warning-offline> B<--critical-offline> B<--warning-degraded> B<--critical-degraded> B<--warning-unsynchronised> B<--critical-unsynchronised>

Thresholds on the counts.

=back

=cut
