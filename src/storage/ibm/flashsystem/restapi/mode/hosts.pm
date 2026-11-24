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

package storage::ibm::flashsystem::restapi::mode::hosts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::misc qw(is_excluded is_not_empty);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_host_output {
    my ($self, %options) = @_;

    my $msg = sprintf('status: %s', $self->{result_values}->{status});

    $msg .= sprintf(', ports: %s', $self->{result_values}->{port_count})
        if (is_not_empty($self->{result_values}->{port_count}));
    $msg .= sprintf(', host cluster: %s', $self->{result_values}->{host_cluster_name})
        if (is_not_empty($self->{result_values}->{host_cluster_name}));
    $msg .= sprintf(', partition: %s', $self->{result_values}->{partition_name})
        if (is_not_empty($self->{result_values}->{partition_name}));

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Hosts: ' },
        { name => 'hosts', type => COUNTER_TYPE_INSTANCE, prefix_output => "Host '%{name}' ",
          message_multiple => 'All hosts are online', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'detected', nlabel => 'hosts.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => '%s declared',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'online', nlabel => 'hosts.online.count', set => {
                key_values => [ { name => 'online' } ],
                output_template => '%s online',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'offline', nlabel => 'hosts.offline.count', set => {
                key_values => [ { name => 'offline' } ],
                output_template => '%s offline',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'degraded', nlabel => 'hosts.degraded.count', set => {
                key_values => [ { name => 'degraded' } ],
                output_template => '%s degraded',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{hosts} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{status} =~ /^degraded$/i',
            warning_default => '%{status} =~ /^offline$/i',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'status' }, { name => 'port_count' },
                    { name => 'host_cluster_name' }, { name => 'partition_name' }
                ],
                closure_custom_output => $self->can('custom_host_output'),
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

    $self->{global} = { detected => 0, online => 0, offline => 0, degraded => 0 };
    $self->{hosts} = {};

    foreach my $entry (@{ $options{custom}->request(command => 'lshost') }) {
        my $name = $entry->{name} // '';
        my $partition = $entry->{partition_name} // '';

        next if (is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}));
        next if (is_excluded($partition, $self->{option_results}->{include_partition}, $self->{option_results}->{exclude_partition}));

        my $status = $entry->{status} // '';

        $self->{global}->{detected}++;
        $self->{global}->{online}++   if ($status =~ /^online$/i);
        $self->{global}->{offline}++  if ($status =~ /^offline$/i);
        $self->{global}->{degraded}++ if ($status =~ /^degraded$/i);

        $self->{hosts}->{$name} = {
            name => $name,
            status => $status,
            port_count => $entry->{port_count} // '',
            host_cluster_name => $entry->{host_cluster_name} // '',
            partition_name => $partition
        };
    }
}

1;

__END__

=head1 MODE

Check the status of the hosts declared on the system.

Every declared host is evaluated. A host that is offline on purpose, a spare
logical partition profile, an idle backup host, still reports offline: acknowledging it in
Centreon records who decided it is expected and when that should be revisited,
which a hard-coded exclusion would not.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=hosts --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx

=over 8

=item B<--include-name>

Filter hosts by name (can be a regexp).

=item B<--exclude-name>

Exclude hosts by name (can be a regexp).

=item B<--include-partition>

Filter hosts by storage partition name (can be a regexp).

=item B<--exclude-partition>

Exclude hosts by storage partition name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.

Threshold on each host. Available macros: C<name>, C<status>, C<port_count>,
C<host_cluster_name>, C<partition_name>.

The natural order of severity is B<inverted> here, on purpose. C<offline> means
no WWPN of that host connects any more: the array cannot tell a deliberately
powered-off server from a failed one, and the common case is the former
(spares, backup hosts), a warning keeps it visible without waking anyone.
C<degraded> means only B<part> of the paths answer: the host is running, in
production, on eaten-into redundancy, and the next lost path cuts its storage.
That is actionable right now (zoning, SFP, switch) and is often the only place
such a fabric fault shows up.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.

Threshold on each host. Available macros: C<name>, C<status>, C<port_count>,
C<host_cluster_name>, C<partition_name>.

Default warning: C<%{status} =~ /^offline$/i>.

The natural order of severity is B<inverted> here, on purpose. C<offline> means
no WWPN of that host connects any more: the array cannot tell a deliberately
powered-off server from a failed one, and the common case is the former
(spares, backup hosts), a warning keeps it visible without waking anyone.
C<degraded> means only B<part> of the paths answer: the host is running, in
production, on eaten-into redundancy, and the next lost path cuts its storage.
That is actionable right now (zoning, SFP, switch) and is often the only place
such a fabric fault shows up.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.

Threshold on each host. Available macros: C<name>, C<status>, C<port_count>,
C<host_cluster_name>, C<partition_name>.

Default critical: C<%{status} =~ /^degraded$/i>.

The natural order of severity is B<inverted> here, on purpose. C<offline> means
no WWPN of that host connects any more: the array cannot tell a deliberately
powered-off server from a failed one, and the common case is the former
(spares, backup hosts), a warning keeps it visible without waking anyone.
C<degraded> means only B<part> of the paths answer: the host is running, in
production, on eaten-into redundancy, and the next lost path cuts its storage.
That is actionable right now (zoning, SFP, switch) and is often the only place
such a fabric fault shows up.

=item B<--warning-offline>

Warning threshold.

Thresholds on the number of offline and degraded hosts.

=item B<--critical-offline>

Critical threshold.

Thresholds on the number of offline and degraded hosts.

=item B<--warning-degraded>

Warning threshold.

Thresholds on the number of offline and degraded hosts.

=item B<--critical-degraded>

Critical threshold.

Thresholds on the number of offline and degraded hosts.

=back

=cut
