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

package apps::backup::rubrik::graphql::mode::cluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw/is_excluded/;
use apps::backup::rubrik::graphql::common qw/timerange_check_options $timerange_filters/;

sub custom_status_output {
    my ($self, %options) = @_;

    my $status = 'status: ' . $self->{result_values}->{status};

    $status .= ', id: '.$self->{result_values}->{id} if $self->{output}->is_verbose();

    $status .= ', system status: ' . $self->{result_values}->{system_status}
    if $self->{result_values}->{system_status} ne '';

    $status .= ', is healthy: '. $self->{result_values}->{is_healthy};
    $status .= ', IPMI: '. $self->{result_values}->{ipmi};

    return $status;
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clusters', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters are ok' }
    ];

    $self->{maps_counters}->{clusters} = [
        { label => 'status', type => COUNTER_KIND_TEXT, critical_default => '%{status} !~ /connected/ || %{system_status} !~ /ok/', set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'system_status' }, { name => 'is_healthy' }, { name => 'system_status_message' }, { name => 'ipmi' }, { name => 'id' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'read', nlabel => 'cluster.io.read.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'read' } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'cluster.io.write.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'write' } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-iops', nlabel => 'cluster.io.read.usage.iops', display_ok => 0, set => {
                key_values => [ { name => 'read_iops' } ],
                output_template => 'read iops: %.2f',
                perfdatas => [
                    { template => '%.2f', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'cluster.io.write.usage.iops', display_ok => 0, set => {
                key_values => [ { name => 'write_iops' } ],
                output_template => 'write iops: %.2f',
                perfdatas => [
                    { template => '%.2f', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'received', nlabel => 'cluster.network.received.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'received' } ],
                output_template => 'received: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'transmitted', nlabel => 'cluster.network.transmitted.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'transmitted' } ],
                output_template => 'transmitted: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },

    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { %$timerange_filters } );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);
    timerange_check_options($self);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $filters = $options{custom}->common_filters();

    $filters->{registrationTime_gt} = $self->{option_results}->{start_time}
        if $self->{option_results}->{start_time} ne '';
    $filters->{registrationTime_lt} = $self->{option_results}->{end_time}
        if $self->{option_results}->{end_time} ne '';
    my $result = $options{custom}->get_cluster_stats( filters => $filters );

    $self->{output}->option_exit(short_msg => "No matching cluster !")
        unless ref $result eq 'ARRAY';
    $self->{clusters} = {};
    foreach my $cluster (@$result) {
    next if $options{custom}->is_common_excluded(id => $cluster->{id}, name => $cluster->{name});

        # Aggregate stats from all nodes
    my %aggregate = ();
    my %average = ();

    $aggregate{$_} = $average{$_} = 0
            foreach qw/networkBytesReceived networkBytesTransmitted readThroughputBytesPerSecond writeThroughputBytesPerSecond iopsReadsPerSecond iopsWritesPerSecond/;

        if (ref $cluster->{clusterNodeStats} eq 'ARRAY') {
            foreach my $node_stat (@{$cluster->{clusterNodeStats} || []}) {
               while (my ($key, $value) = each %$node_stat) {
                    $aggregate{$key} += $value;
               }
            }
            my $count = @{$cluster->{clusterNodeStats}};

            # Calculate averages
            while (my ($key, $value) = each %aggregate) {
                $average{$key} = $count ? $value / $count : 0;
            }
        }

    my $ipmi = 'none';
    if ($cluster->{ipmiInfo} && $cluster->{ipmiInfo}->{isAvailable}) {
            my @mod;
            push @mod, "Https" if $cluster->{ipmiInfo}->{usesHttps};
            push @mod, "Ikvm" if $cluster->{ipmiInfo}->{usesIkvm};
            $ipmi = join '+', @mod;
        }

        $self->{clusters}->{ $cluster->{name} } = {
            name => $cluster->{name},
            id => $cluster->{id},
            status => lc $cluster->{status},
            system_status => lc ($cluster->{systemStatus} // ''),
            system_status_message => $cluster->{systemStatusMessage} // '',
            is_healthy => $cluster->{isHealthy} ? 'true' : 'false',
            read => $average{'readThroughputBytesPerSecond'},
            write => $average{'writeThroughputBytesPerSecond'},
            received => $average{'networkBytesReceived'},
            transmitted => $average{'networkBytesTransmitted'},
            read_iops => $average{'iopsReadsPerSecond'},
            write_iops => $average{'iopsWritesPerSecond'},
            ipmi => $ipmi
        };
    }

    $self->{output}->option_exit(short_msg => "No matching cluster !")
        unless %{$self->{clusters}};
}

1;

__END__

=head1 MODE

Check Rubrik cluster using GraphQL API.

=over 8

=item B<--start-time>

Set start time for filtering clusters by registration date. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--end-time>

Set end time for filtering clusters by registration date. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--last>

Set duration to filter last registered clusters. Use 'd' for day, 'h' for hour, 'm' for minute (e.g., C<24h>, C<30m>, C<7d>).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /connected/ || %{system_status} !~ /ok/').
You can use the following variables: %{status}, %{name}

=item B<--warning-read>

Warning threshold for read throughput (B/s).

=item B<--critical-read>

Critical threshold for read throughput (B/s).

=item B<--warning-write>

Warning threshold for write throughput (B/s).

=item B<--critical-write>

Critical threshold for write throughput (B/s).

=item B<--warning-read-iops>

Warning threshold for read IOPS.

=item B<--critical-read-iops>

Critical threshold for read IOPS.

=item B<--warning-write-iops>

Warning threshold for write IOPS.

=item B<--critical-write-iops>

Critical threshold for write IOPS.

=item B<--warning-received>

Warning threshold for network bytes received per second (B/s).

=item B<--critical-received>

Critical threshold for network bytes received per second (B/s).

=item B<--warning-transmitted>

Warning threshold for network bytes transmitted per second (B/s).

=item B<--critical-transmitted>

Critical threshold for network bytes transmitted per second (B/s).

=back

=cut
