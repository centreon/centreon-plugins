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
        { label => 'backend-latency-read', nlabel => 'cluster.vsan.backend.latency.read.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'latencyAvgRead' } ],
                output_template => 'read latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0 }
                ]
            }
        },
        { label => 'backend-latency-write', nlabel => 'cluster.vsan.backend.latency.write.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'latencyAvgWrite' } ],
                output_template => 'write latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0 }
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
        'filter'             => { name => 'filter' },
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
        $self->{cluster}->{$cluster_name} = {
            display => $cluster_name,
            %{$response->{data}->{$cluster_id}->{cluster_domcompmgr}},
        };
    }    
}

1;

__END__

=head1 MODE

Check Vsan cluster usage

=over 8

=item B<--cluster-name>

cluster to check.
If not set, we check all clusters.

=item B<--filter>

Cluster name is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'backend-write-usage', 'backend-read-usage',
'backend-outstanding-io', 'backend-congestions', 
'backend-throughput-read', 'backend-throughput-write'
.

=back

=cut
