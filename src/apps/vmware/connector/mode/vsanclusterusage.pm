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

package apps::vmware::connector::mode::vsanclusterusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cluster', type => 1, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters are ok' }
    ];
    
    $self->{maps_counters}->{cluster} = [
        { label => 'backend-read-usage', nlabel => 'cluster.vsan.backend.read.usage.iops', set => {
                key_values => [ { name => 'iopsRead' } ],
                output_template => 'read IOPS: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0 }
                ]
            }
        },
        { label => 'backend-write-usage', nlabel => 'cluster.vsan.backend.write.usage.iops', set => {
                key_values => [ { name => 'iopsWrite' } ],
                output_template => 'write IOPS: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0 }
                ]
            }
        },
        { label => 'backend-congestions', nlabel => 'cluster.vsan.backend.congestions.count', set => {
                key_values => [ { name => 'congestion' } ],
                output_template => 'congestions: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'backend-outstanding-io', nlabel => 'cluster.vsan.backend.outstanding.io.count', set => {
                key_values => [ { name => 'oio' } ],
                output_template => 'outstanding IO: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'backend-throughput-read', nlabel => 'cluster.vsan.backend.throughput.read.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'throughputRead' } ],
                output_template => 'read throughput: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'backend-throughput-write', nlabel => 'cluster.vsan.backend.throughput.write.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'throughputWrite' } ],
                output_template => 'write throughput: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'backend-latency-read', nlabel => 'cluster.vsan.backend.latency.read.microseconds', display_ok => 0, set => {
                key_values => [ { name => 'latencyAvgRead' } ],
                output_template => 'read latency: %s µs',
                perfdatas => [
                    { template => '%s', unit => 'µs', min => 0 }
                ]
            }
        },
        { label => 'backend-latency-write', nlabel => 'cluster.vsan.backend.latency.write.microseconds', display_ok => 0, set => {
                key_values => [ { name => 'latencyAvgWrite' } ],
                output_template => 'write latency: %s µs',
                perfdatas => [
                    { template => '%s', unit => 'µs', min => 0 }
                ]
            }
        }
    ];
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{display} . "' vsan backend ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'cluster-name:s'     => { name => 'cluster_name' },
        'scope-datacenter:s' => { name => 'scope_datacenter' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cluster} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'vsanclusterusage'
    );

    foreach my $cluster_id (keys %{$response->{data}}) {
        my $cluster_name = $response->{data}->{$cluster_id}->{name};
        next if ( !centreon::plugins::misc::is_empty($self->{option_results}->{cluster_name})
                and $cluster_name !~ /$self->{option_results}->{cluster_name}/ );

        $self->{cluster}->{$cluster_name} = {
            display => $cluster_name,
            %{$response->{data}->{$cluster_id}->{cluster_domcompmgr}},
        };
    }
    if ( scalar(keys(%{$self->{cluster}}) ) == 0) {
        my $explanation = centreon::plugins::misc::is_empty($self->{option_results}->{cluster_name}) ? '' : ' matching /' . $self->{option_results}->{cluster_name} . '/';
        $self->{output}->output_add(severity => 'UNKNOWN', short_msg => "No clusters found" . $explanation);
    }
}

1;

__END__

=head1 MODE

Check VMware vSAN cluster usage.

=over 8

=item B<--cluster-name>

Define which clusters should be monitored based on their name.
This option will be treated as a regular expression.

=item B<--scope-datacenter>

Define which clusters to monitor based on their data center's name.
This option will be treated as a regular expression.

=item B<--warning-backend-write-usage>

Thresholds.

=item B<--critical-backend-write-usage>

Thresholds.

=item B<--warning-backend-read-usage>

Thresholds.

=item B<--critical-backend-read-usage>

Thresholds.

=item B<--warning-backend-outstanding-io>

Thresholds.

=item B<--critical-backend-outstanding-io>

Thresholds.

=item B<--warning-backend-congestions>

Thresholds.

=item B<--critical-backend-congestions>

Thresholds.

=item B<--warning-backend-throughput-read>

Thresholds.

=item B<--critical-backend-throughput-read>

Thresholds.

=item B<--warning-backend-throughput-write>

Thresholds.

=item B<--critical-backend-throughput-write>

Thresholds.

=item B<--warning-backend-latency-read>

Thresholds in microseconds.

=item B<--critical-backend-latency-read>

Thresholds in microseconds.

=item B<--warning-backend-latency-write>

Thresholds in microseconds.

=item B<--critical-backend-latency-write>

Thresholds in microseconds.

=back

=cut
