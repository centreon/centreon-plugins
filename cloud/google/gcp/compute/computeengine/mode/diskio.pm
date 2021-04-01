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

package cloud::google::gcp::compute::computeengine::mode::diskio;

use base qw(cloud::google::gcp::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'instance/disk/read_bytes_count' => {
            output_string => 'read: %.2f',
            perfdata => {
                absolute => {
                    nlabel => 'computeengine.disk.read.volume.bytes',
                    format => '%.2f',
                    unit => 'B',
                    change_bytes => 1
                },
                per_second => {
                    nlabel => 'computeengine.disk.read.volume.bytespersecond',
                    format => '%.2f',
                    unit => 'B/s',
                    change_bytes => 1
                }
            },
            threshold => 'read-volume',
            order => 1
        },
        'instance/disk/throttled_read_bytes_count' => {
            output_string => 'throttled read: %.2f',
            perfdata => {
                absolute => {
                    nlabel => 'computeengine.disk.throttled.read.volume.bytes',
                    format => '%.2f',
                    unit => 'B',
                    change_bytes => 1
                },
                per_second => {
                    nlabel => 'computeengine.disk.throttled.read.volume.bytespersecond',
                    format => '%.2f',
                    unit => 'B/s',
                    change_bytes => 1
                }
            },
            threshold => 'throttled-read-volume',
            order => 2
        },
        'instance/disk/write_bytes_count' => {
            output_string => 'write: %.2f',
            perfdata => {
                absolute => {
                    nlabel => 'computeengine.disk.write.volume.bytes',
                    format => '%.2f',
                    unit => 'B',
                    change_bytes => 1
                },
                per_second => {
                    nlabel => 'computeengine.disk.write.volume.bytespersecond',
                    format => '%.2f',
                    unit => 'B/s',
                    change_bytes => 1
                }
            },
            threshold => 'write-volume',
            order => 3
        },
        'instance/disk/throttled_write_bytes_count' => {
            output_string => 'throttled write: %.2f',
            perfdata => {
                absolute => {
                    nlabel => 'computeengine.disk.throttled.write.volume.bytes',
                    format => '%.2f',
                    unit => 'B',
                    change_bytes => 1
                },
                per_second => {
                    nlabel => 'computeengine.disk.throttled.write.volume.bytespersecond',
                    format => '%.2f',
                    unit => 'B/s',
                    change_bytes => 1
                }
            },
            threshold => 'throttled-write-volume',
            order => 4
        },
        'instance/disk/read_ops_count' => {
            output_string => 'read OPS: %.2f',
            perfdata => {
                absolute => {
                    nlabel => 'computeengine.disk.read.ops.count',
                    format => '%.2f'
                },
                per_second => {
                    nlabel => 'computeengine.disk.read.ops.persecond',
                    format => '%.2f'
                }
            },
            threshold => 'read-ops',
            order => 5
        },
        'instance/disk/write_ops_count' => {
            output_string => 'write OPS: %.2f',
            perfdata => {
                absolute => {
                    nlabel => 'computeengine.disk.write.ops.count',
                    format => '%.2f'
                },
                per_second => {
                    nlabel => 'computeengine.disk.write.ops.persecond',
                    format => '%.2f'
                }
            },
            threshold => 'write-ops',
            order => 6
        }
    };

    return $metrics_mapping;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'dimension-name:s'     => { name => 'dimension_name', default => 'metric.labels.instance_name' },
        'dimension-operator:s' => { name => 'dimension_operator', default => 'equals' },
        'dimension-value:s'    => { name => 'dimension_value' },
        'filter-metric:s'      => { name => 'filter_metric' },
        "per-second"           => { name => 'per_second' },
        'timeframe:s'          => { name => 'timeframe' },
        'aggregation:s@'       => { name => 'aggregation' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{gcp_api} = 'compute.googleapis.com';
    $self->{gcp_dimension_name} = (!defined($self->{option_results}->{dimension_name}) || $self->{option_results}->{dimension_name} eq '') ? 'metric.labels.instance_name' : $self->{option_results}->{dimension_name};
    $self->{gcp_dimension_zeroed} = 'metric.labels.instance_name';
    $self->{gcp_instance_key} = 'metric.labels.instance_name';
    $self->{gcp_dimension_operator} = $self->{option_results}->{dimension_operator};
    $self->{gcp_dimension_value} = $self->{option_results}->{dimension_value};
}

1;

__END__

=head1 MODE

Check Compute Engine instances disk IO metrics.

Example:

perl centreon_plugins.pl --plugin=cloud::google::gcp::compute::computeengine::plugin
--mode=diskio --dimension-value=mycomputeinstance --filter-metric='throttled'
--aggregation='average' --critical-throttled-write-volume='10' --verbose

Default aggregation: 'average' / All aggregations are valid.

=over 8

=item B<--dimension-name>

Set dimension name (Default: 'metric.labels.instance_name').

=item B<--dimension-operator>

Set dimension operator (Default: 'equals'. Can also be: 'regexp', 'starts').

=item B<--dimension-value>

Set dimension value (Required).

=item B<--filter-metric>

Filter metrics (Can be: 'instance/disk/read_bytes_count', 'instance/disk/throttled_read_bytes_count',
'instance/disk/write_bytes_count', 'instance/disk/throttled_write_bytes_count',
'instance/disk/read_ops_count', 'instance/disk/write_ops_count') (Can be a regexp).

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour).

=item B<--aggregation>

Set monitor aggregation (Can be multiple, Can be: 'minimum', 'maximum', 'average', 'total').

=item B<--warning-*> B<--critical-*>

Thresholds (Can be: 'read-volume', 'throttled-read-volume',
'write-volume', 'throttled-write-volume', 'read-ops', 'write-ops').

=item B<--per-second>

Change the data to be unit/sec.

=back

=cut
