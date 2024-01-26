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

package storage::dell::powerstore::restapi::mode::clusters;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub cluster_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking cluster '%s'",
        $options{instance}
    );
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return sprintf(
        "cluster '%s' ",
        $options{instance}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of clusters ';
}

sub prefix_read_latency_output {
    my ($self, %options) = @_;

    return 'read latency ';
}

sub prefix_write_latency_output {
    my ($self, %options) = @_;

    return 'write latency ';
}

sub prefix_read_iops_output {
    my ($self, %options) = @_;

    return 'read iops ';
}

sub prefix_write_iops_output {
    my ($self, %options) = @_;

    return 'write iops ';
}

sub prefix_read_bandwidth_output {
    my ($self, %options) = @_;

    return 'read bandwidth ';
}

sub prefix_write_bandwidth_output {
    my ($self, %options) = @_;

    return 'write bandwidth ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'clusters', type => 3, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All clusters are ok',
            group => [
                { name => 'read_latency', type => 0, cb_prefix_output => 'prefix_read_latency_output' },
                { name => 'write_latency', type => 0, cb_prefix_output => 'prefix_write_latency_output' },
                { name => 'read_iops', type => 0, cb_prefix_output => 'prefix_read_iops_output' },
                { name => 'write_iops', type => 0, cb_prefix_output => 'prefix_write_iops_output' },
                { name => 'read_bandwidth', type => 0, cb_prefix_output => 'prefix_read_bandwidth_output' },
                { name => 'write_bandwidth', type => 0, cb_prefix_output => 'prefix_write_bandwidth_output' }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'clusters-detected', display_ok => 0, nlabel => 'clusters.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    foreach ('read', 'write') {
        $self->{maps_counters}->{$_ . '_latency'} = [];
        foreach my $sampling ('5m', '30m', '1h', '24h') {
            push @{$self->{maps_counters}->{$_ . '_latency'}}, {
                label => $_ . '-latency-' . $sampling, nlabel => 'cluster.io.'. $_ . '.latency.' . $sampling . '.milliseconds', set => {
                    key_values => [ { name => $sampling } ],
                    output_template => '%.3f ms (' . $sampling . ')',
                    perfdatas => [
                        { template => '%.3f', unit => 'ms', min => 0, label_extra_instance => 1 }
                    ]
                }
            };
        }

        foreach my $sampling ('5m', '30m', '1h', '24h') {
            push @{$self->{maps_counters}->{$_ . '_iops'}}, {
                label => $_ . '-iops-' . $sampling, nlabel => 'cluster.io.'. $_ . '.' . $sampling . '.iops', set => {
                    key_values => [ { name => $sampling } ],
                    output_template => '%d (' . $sampling . ')',
                    perfdatas => [
                        { template => '%d', unit => 'iops', min => 0, label_extra_instance => 1 }
                    ]
                }
            };
        }

        foreach my $sampling ('5m', '30m', '1h', '24h') {
            push @{$self->{maps_counters}->{$_ . '_bandwidth'}}, {
                label => $_ . '-bandwidth-' . $sampling, nlabel => 'cluster.io.'. $_ . '.bandwidth.' . $sampling . '.bytespersecond', set => {
                    key_values => [ { name => $sampling } ],
                    output_template => '%.2f%s/s (' . $sampling . ')',
                    output_change_bytes => 1,
                    perfdatas => [
                        { template => '%.2f', unit => 'B/s', min => 0, label_extra_instance => 1 }
                    ]
                }
            };
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-id:s'   => { name => 'filter_id' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $clusters = $options{custom}->get_performance_metrics_by_clusters();

    $self->{global} = { detected => 0 };
    $self->{clusters} = {};

    foreach my $cluster_id (keys %$clusters) {
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $cluster_id !~ /$self->{option_results}->{filter_id}/);

        $self->{global}->{detected}++;

        $self->{clusters}->{ $cluster_id } = {
            latency => {},
            iops => {},
            bandwidth => {}
        };

        foreach my $sampling ('5m', '30m', '1h', '24h') {
            foreach my $metric ('read_latency', 'write_latency', 'read_iops', 'write_iops', 'read_bandwidth', 'write_bandwidth') {
                $self->{clusters}->{ $cluster_id }->{$metric}->{$sampling} = 0;
                $self->{clusters}->{ $cluster_id }->{$metric}->{'num_' . $sampling} = 0;
            }
        }

        my $i = 0;
        while (my $entry = pop(@{$clusters->{$cluster_id}})) {
            foreach ('latency', 'iops', 'bandwidth') {
                if ($i == 0) {
                    $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'5m'} += $entry->{'avg_read_' . $_};
                    $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'5m'} += $entry->{'avg_write_' . $_};
                }
                if ($i < 5) {
                    $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'30m'} += $entry->{'avg_read_' . $_};
                    $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'30m'} += $entry->{'avg_write_' . $_};
                    $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{num_30m}++;
                    $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{num_30m}++;
                }
                if ($i < 10) {
                    $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'1h'} += $entry->{'avg_read_' . $_};
                    $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'1h'} += $entry->{'avg_write_' . $_};
                    $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{num_1h}++;
                    $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{num_1h}++;
                }
                $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'24h'} += $entry->{'avg_read_' . $_};
                $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'24h'} += $entry->{'avg_write_' . $_};
                $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{num_24h}++;
                $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{num_24h}++;
            }

            $i++;
        }

        foreach ('latency', 'iops', 'bandwidth') {
            if ($_ eq 'latency') {
                $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'5m'} = $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'5m'} / 1000;
                $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'5m'} = $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'5m'} / 1000;
                $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'30m'} =
                    $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'30m'} / $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{num_30m} / 1000;
                $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'30m'} =
                    $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'30m'} / $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{num_30m} / 1000;
                $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'1h'} =
                    $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'1h'} / $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{num_1h} / 1000;
                $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'1h'} =
                    $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'1h'} / $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{num_1h} / 1000;
                $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'24h'} =
                    $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'24h'} / $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{num_24h} / 1000;
                $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'24h'} =
                    $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'24h'} / $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{num_24h} / 1000;
            } else {
                $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'30m'} /= $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{num_30m};
                $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'30m'} /= $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{num_30m};
                $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'1h'} /= $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{num_1h};
                $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'1h'} /= $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{num_1h};
                $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{'24h'} /= $self->{clusters}->{ $cluster_id }->{'read_' . $_}->{num_24h};
                $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{'24h'} /= $self->{clusters}->{ $cluster_id }->{'write_' . $_}->{num_24h};
            }
        }
    }
}

1;

__END__

=head1 MODE

Check clusters.

=over 8

=item B<--filter-id>

Filter clusters by id.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'clusters-detected',
'read-iops-5m', 'read-iops-30m', 'read-iops-1h', 'read-iops-24h',
'write-iops-5m', 'write-iops-30m', 'write-iops-1h', 'write-iops-24h',
'read-latency-5m', 'read-latency-30m', 'read-latency-1h', 'read-latency-24h',
'write-latency-5m', 'write-latency-30m', 'write-latency-1h', 'write-latency-24h',
'read-bandwidth-5m', 'read-bandwidth-30m', 'read-bandwidth-1h', 'read-bandwidth-24h',
'write-bandwidth-5m', 'write-bandwidth-30m', 'write-bandwidth-1h', 'write-bandwidth-24h'.

=back

=cut
