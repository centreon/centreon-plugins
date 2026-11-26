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

package storage::ibm::flashsystem::restapi::mode::volumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded is_not_empty);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_volume_output {
    my ($self, %options) = @_;

    my $msg = sprintf('status: %s', $self->{result_values}->{status});

    $msg .= sprintf(', pool: %s', $self->{result_values}->{mdisk_grp_name})
        if (is_not_empty($self->{result_values}->{mdisk_grp_name}));
    $msg .= sprintf(', volume group: %s', $self->{result_values}->{volume_group_name})
        if (is_not_empty($self->{result_values}->{volume_group_name}));
    $msg .= sprintf(', write cache: %s', $self->{result_values}->{fast_write_state})
        if (is_not_empty($self->{result_values}->{fast_write_state})
            && $self->{result_values}->{fast_write_state} !~ /^(empty|not_empty)$/i);
    $msg .= ', formatting'
        if ($self->{result_values}->{formatting} =~ /^yes$/i);
    $msg .= ', copies not synchronised'
        if ($self->{result_values}->{sync} =~ /^no$/i);

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Volumes: ' },
        { name => 'volumes', type => COUNTER_TYPE_INSTANCE, prefix_output => "Volume '%{name}' ",
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
        { label => 'degraded', nlabel => 'volumes.degraded.count', display_ok => 0, set => {
                key_values => [ { name => 'degraded' } ],
                output_template => '%s degraded',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'offline', nlabel => 'volumes.offline.count', display_ok => 0, set => {
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

    $self->{maps_counters}->{volumes} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{status} =~ /^offline$/i or %{fast_write_state} =~ /^corrupt$/i',
            warning_default => '%{status} =~ /^degraded$/i or %{sync} =~ /^no$/i',
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
        'include-name:s'         => { name => 'include_name' },
        'exclude-name:s'         => { name => 'exclude_name' },
        'include-pool:s'         => { name => 'include_pool' },
        'exclude-pool:s'         => { name => 'exclude_pool' },
        'include-volume-group:s' => { name => 'include_volume_group' },
        'exclude-volume-group:s' => { name => 'exclude_volume_group' },
        'add-all-volumes'        => { name => 'add_all_volumes' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # Copy synchronisation is only in lsvdiskcopy: a volume can be online with
    # an out-of-sync copy.
    my %unsynced;
    foreach my $copy (@{$options{custom}->request_optional(command => 'lsvdiskcopy')}) {
        $unsynced{$copy->{vdisk_name} // ''} = 1 if (($copy->{sync} // '') =~ /^no$/i);
    }

    $self->{global} = { detected => 0, online => 0, degraded => 0, offline => 0, unsynchronised => 0 };
    $self->{volumes} = {};

    foreach my $volume (@{$options{custom}->request(command => 'lsvdisk')}) {
        my $name = $volume->{name} // '';
        my $pool = $volume->{mdisk_grp_name} // '';
        my $group = $volume->{volume_group_name} // '';

        next if (is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}));
        next if (is_excluded($pool, $self->{option_results}->{include_pool}, $self->{option_results}->{exclude_pool}));
        next if (is_excluded($group, $self->{option_results}->{include_volume_group}, $self->{option_results}->{exclude_volume_group}));

        my $status = $volume->{status} // '';
        my $fast_write = $volume->{fast_write_state} // '';
        my $formatting = $volume->{formatting} // '';
        my $sync = $unsynced{$name} ? 'no' : 'yes';

        $self->{global}->{detected}++;
        $self->{global}->{online}++ if ($status =~ /^online$/i);
        $self->{global}->{degraded}++ if ($status =~ /^degraded$/i);
        $self->{global}->{offline}++ if ($status =~ /^offline$/i);
        $self->{global}->{unsynchronised}++ if ($sync eq 'no');

        my $healthy = $status =~ /^online$/i && $fast_write !~ /^corrupt$/i && $sync eq 'yes' && $formatting !~ /^yes$/i;
        next if ($healthy && !defined($self->{option_results}->{add_all_volumes}));

        $self->{volumes}->{$name} = {
            name => $name,
            status => $status,
            fast_write_state => $fast_write,
            formatting => $formatting,
            sync => $sync,
            mdisk_grp_name => $pool,
            volume_group_name => $group
        };
    }
}

1;

__END__

=head1 MODE

Check volumes.

Only the volumes in an abnormal state are reported by default.

=over 8

=item B<--include-name>

Filter volumes by name (can be a regexp).

=item B<--exclude-name>

Exclude volumes by name (can be a regexp).

=item B<--include-pool>

Filter volumes by pool name (can be a regexp).

=item B<--exclude-pool>

Exclude volumes by pool name (can be a regexp).

=item B<--include-volume-group>

Filter volumes by volume group name (can be a regexp).

=item B<--exclude-volume-group>

Exclude volumes by volume group name (can be a regexp).

=item B<--add-all-volumes>

Check all volumes, not only the ones in an abnormal state.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{status} =~ /^degraded$/i or %{sync} =~ /^no$/i'>).
You can use the following variables: C<%{name}>, C<%{status}>, C<%{fast_write_state}>, C<%{formatting}>, C<%{sync}>, C<%{mdisk_grp_name}>, C<%{volume_group_name}>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} =~ /^offline$/i or %{fast_write_state} =~ /^corrupt$/i'>).
You can use the following variables: C<%{name}>, C<%{status}>, C<%{fast_write_state}>, C<%{formatting}>, C<%{sync}>, C<%{mdisk_grp_name}>, C<%{volume_group_name}>

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{status}>, C<%{fast_write_state}>, C<%{formatting}>, C<%{sync}>, C<%{mdisk_grp_name}>, C<%{volume_group_name}>

=item B<--warning-detected>

Threshold.

=item B<--critical-detected>

Threshold.

=item B<--warning-online>

Threshold.

=item B<--critical-online>

Threshold.

=item B<--warning-degraded>

Threshold.

=item B<--critical-degraded>

Threshold.

=item B<--warning-offline>

Threshold.

=item B<--critical-offline>

Threshold.

=item B<--warning-unsynchronised>

Threshold.

=item B<--critical-unsynchronised>

Threshold.

=back

=cut
