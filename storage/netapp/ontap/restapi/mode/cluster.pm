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

package storage::netapp::ontap::restapi::mode::cluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [link status: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{link_status}
    );
}

sub cluster_long_output {
    my ($self, %options) = @_;

    return "checking cluster '" . $options{instance_value}->{display} . "'";
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "cluster '" . $options{instance_value}->{display} . "' ";
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "node '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clusters', type => 3, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All clusters are ok',
            group => [
                { name => 'global', type => '0' },
                { name => 'nodes', display_long => 1, cb_prefix_output => 'prefix_node_output',  message_multiple => 'nodes are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'read', nlabel => 'cluster.io.read.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'read', per_second => 1 }, { name => 'display' } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'cluster.io.write.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'write', per_second => 1 }, { name => 'display' } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-iops', nlabel => 'cluster.io.read.usage.iops', set => {
                key_values => [ { name => 'read_iops' }, { name => 'display' } ],
                output_template => 'read iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'cluster.io.write.usage.iops', set => {
                key_values => [ { name => 'write_iops' }, { name => 'display' } ],
                output_template => 'write iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-latency', nlabel => 'cluster.io.read.latency.milliseconds', set => {
                key_values => [ { name => 'read_latency' }, { name => 'display' } ],
                output_template => 'read latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0 }
                ]
            }
        },
        { label => 'write-latency', nlabel => 'cluster.io.write.latency.milliseconds', set => {
                key_values => [ { name => 'write_latency' }, { name => 'display' } ],
                output_template => 'write latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'node-status', type => 2, critical_default => '%{state} ne "online"', set => {
                key_values => [ { name => 'state' }, { name => 'link_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $cluster = $options{custom}->request_api(endpoint => '/api/cluster?fields=*');

    $self->{clusters} = {
        $cluster->{name} => {
            display => $cluster->{name},
            global => {
                display       => $cluster->{name},
                read          => $cluster->{statistics}->{throughput_raw}->{read},
                write         => $cluster->{statistics}->{throughput_raw}->{write},
                read_iops     => $cluster->{metric}->{iops}->{read},
                write_iops    => $cluster->{metric}->{iops}->{write},
                read_latency  => $cluster->{metric}->{latency}->{read},
                write_latency => $cluster->{metric}->{latency}->{write}
            },
            nodes => {}
        }
    };

    my $nodes = $options{custom}->request_api(endpoint => '/api/cluster/nodes?fields=*');
    foreach (@{$nodes->{records}}) {
        $self->{clusters}->{ $cluster->{name} }->{nodes}->{ $_->{name} } = {
            display => $_->{name},
            state => $_->{service_processor}->{state},
            link_status => $_->{service_processor}->{link_status}
        };
    }

    $self->{cache_name} = 'netapp_ontap_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check cluster.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='node-status'

=item B<--unknown-node-status>

Set unknown threshold for status.
Can used special variables like: %{state}, %{link_status}, %{display}

=item B<--warning-node-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{link_status}, %{display}

=item B<--critical-node-status>

Set critical threshold for status (Default: '%{state} ne "online"').
Can used special variables like: %{state}, %{link_status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization' (%), 'read' (B/s), 'write' (B/s), 'read-iops', 'write-iops'.

=back

=cut
