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

package storage::ibm::flashsystem::restapi::mode::performance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_empty);

my $measures = [
    { stat => 'vdisk_ms',           key => 'latency',            unit => 'ms' },
    { stat => 'vdisk_r_ms',         key => 'read_latency',       unit => 'ms' },
    { stat => 'vdisk_w_ms',         key => 'write_latency',      unit => 'ms' },
    { stat => 'vdisk_io',           key => 'iops',               unit => 'iops' },
    { stat => 'vdisk_mb',           key => 'bandwidth',          unit => 'B/s', scale => 1024 * 1024 },
    { stat => 'cpu_pc',             key => 'cpu',                unit => '%' },
    { stat => 'compression_cpu_pc', key => 'compression_cpu',    unit => '%' },
    { stat => 'write_cache_pc',     key => 'write_cache',        unit => '%' },
    { stat => 'total_cache_pc',     key => 'total_cache',        unit => '%' },
    { stat => 'mdisk_ms',           key => 'backend_latency',    unit => 'ms' },
    { stat => 'drive_ms',           key => 'drive_latency',      unit => 'ms' },
    { stat => 'fc_io',              key => 'fc_iops',            unit => 'iops' },
    { stat => 'fc_mb',              key => 'fc_bandwidth',       unit => 'B/s', scale => 1024 * 1024 }
];

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'system', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Performance: ' },
        { name => 'nodes', type => COUNTER_TYPE_INSTANCE, prefix_output => "Node '%{name}' ",
          message_multiple => 'All node CPUs are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'node-cpu', nlabel => 'node.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' }, { name => 'name' } ],
                output_template => 'cpu %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' } ]
            }
        }
    ];

    $self->{maps_counters}->{system} = [
        { label => 'latency', nlabel => 'system.io.latency.milliseconds', set => {
                key_values => [ { name => 'latency' } ],
                output_template => 'latency %.3f ms',
                perfdatas => [ { template => '%.3f', unit => 'ms', min => 0 } ]
            }
        },
        { label => 'read-latency', nlabel => 'system.io.read.latency.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'read_latency' } ],
                output_template => 'read %.3f ms',
                perfdatas => [ { template => '%.3f', unit => 'ms', min => 0 } ]
            }
        },
        { label => 'write-latency', nlabel => 'system.io.write.latency.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'write_latency' } ],
                output_template => 'write %.3f ms',
                perfdatas => [ { template => '%.3f', unit => 'ms', min => 0 } ]
            }
        },
        { label => 'iops', nlabel => 'system.io.usage.iops', set => {
                key_values => [ { name => 'iops' } ],
                output_template => '%s IOPS',
                perfdatas => [ { template => '%s', unit => 'iops', min => 0 } ]
            }
        },
        { label => 'bandwidth', nlabel => 'system.io.usage.bytespersecond', set => {
                key_values => [ { name => 'bandwidth' } ],
                output_template => 'bandwidth %s %s/s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%d', unit => 'B/s', min => 0 } ]
            }
        },
        { label => 'cpu', nlabel => 'system.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' } ],
                output_template => 'cpu %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0, max => 100 } ]
            }
        },
        { label => 'compression-cpu', nlabel => 'system.cpu.compression.utilization.percentage', display_ok => 0, set => {
                key_values => [ { name => 'compression_cpu' } ],
                output_template => 'compression cpu %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0, max => 100 } ]
            }
        },
        { label => 'write-cache', nlabel => 'system.cache.write.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'write_cache' } ],
                output_template => 'write cache %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0, max => 100 } ]
            }
        },
        { label => 'total-cache', nlabel => 'system.cache.total.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'total_cache' } ],
                output_template => 'total cache %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0, max => 100 } ]
            }
        },
        { label => 'backend-latency', nlabel => 'system.backend.latency.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'backend_latency' } ],
                output_template => 'backend %.3f ms',
                perfdatas => [ { template => '%.3f', unit => 'ms', min => 0 } ]
            }
        },
        { label => 'drive-latency', nlabel => 'system.drive.latency.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'drive_latency' } ],
                output_template => 'drives %.3f ms',
                perfdatas => [ { template => '%.3f', unit => 'ms', min => 0 } ]
            }
        },
        { label => 'fc-iops', nlabel => 'system.fc.usage.iops', display_ok => 0, set => {
                key_values => [ { name => 'fc_iops' } ],
                output_template => 'fc %s IOPS',
                perfdatas => [ { template => '%s', unit => 'iops', min => 0 } ]
            }
        },
        { label => 'fc-bandwidth', nlabel => 'system.fc.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'fc_bandwidth' } ],
                output_template => 'fc %s %s/s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%d', unit => 'B/s', min => 0 } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'add-peaks' => { name => 'add_peaks' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $system = $options{custom}->request(command => 'lssystem')->[0];
    $self->{output}->option_exit(
        short_msg => 'Statistics collection is ' . $system->{statistics_status}
            . ' on this system: the counters would be stale.'
    ) if (defined($system->{statistics_status}) && $system->{statistics_status} !~ /^on$/i);

    my %stats;
    foreach my $entry (@{$options{custom}->request(command => 'lssystemstats')}) {
        next if (ref($entry) ne 'HASH' || !defined($entry->{stat_name}));
        $stats{$entry->{stat_name}} = $entry;
    }

    $self->{nodes} = {};
    foreach my $entry (@{$options{custom}->request_optional(command => 'lsnodecanisterstats')}) {
        next if (ref($entry) ne 'HASH' || ($entry->{stat_name} // '') ne 'cpu_pc');
        my $node = $entry->{node_name};
        my $value = $entry->{stat_current};
        next if (is_empty($node) || !defined($value) || $value !~ /^-?\d+(?:\.\d+)?$/);
        $self->{nodes}->{$node} = { name => $node, cpu => $value };
    }

    $self->{system} = {};
    my @peaks;

    foreach my $measure (@$measures) {
        my $entry = $stats{$measure->{stat}};
        next if (!defined($entry));

        my $current = $entry->{stat_current};
        next if (!defined($current) || $current !~ /^-?\d+(?:\.\d+)?$/);

        $self->{system}->{$measure->{key}} = $current * ($measure->{scale} // 1);

        next if (!defined($self->{option_results}->{add_peaks}));
        my $peak = $entry->{stat_peak};
        next if (!defined($peak) || $peak !~ /^-?\d+(?:\.\d+)?$/);
        my $peak_display = $peak . $measure->{unit};
        if (defined($measure->{scale})) {
            my ($value, $unit) = $self->{perfdata}->change_bytes(value => $peak * $measure->{scale});
            $peak_display = sprintf('%.2f %s/s', $value, $unit);
        }
        push @peaks, sprintf(
            '%s peak %s at %s',
            $measure->{stat}, $peak_display, $entry->{stat_peak_time} // 'unknown'
        );
    }

    $self->{output}->option_exit(short_msg => 'No usable counter returned by lssystemstats.')
        if (scalar(keys %{$self->{system}}) == 0);

    $self->{output}->output_add(long_msg => join("\n", @peaks)) if (scalar(@peaks) > 0);
}

1;

__END__

=head1 MODE

Check system performance: latency, IOPS, throughput, CPU and cache usage.

=over 8

=item B<--add-peaks>

Add the peak value of each counter, and its time, in the long output.

=item B<--warning-latency>

Threshold in milliseconds.

=item B<--critical-latency>

Threshold in milliseconds.

=item B<--warning-read-latency>

Threshold in milliseconds.

=item B<--critical-read-latency>

Threshold in milliseconds.

=item B<--warning-write-latency>

Threshold in milliseconds.

=item B<--critical-write-latency>

Threshold in milliseconds.

=item B<--warning-iops>

Threshold in IOPS.

=item B<--critical-iops>

Threshold in IOPS.

=item B<--warning-bandwidth>

Threshold in bytes per second.

=item B<--critical-bandwidth>

Threshold in bytes per second.

=item B<--warning-cpu>

Threshold in percentage.

=item B<--critical-cpu>

Threshold in percentage.

=item B<--warning-compression-cpu>

Threshold in percentage.

=item B<--critical-compression-cpu>

Threshold in percentage.

=item B<--warning-write-cache>

Threshold in percentage.

=item B<--critical-write-cache>

Threshold in percentage.

=item B<--warning-total-cache>

Threshold in percentage.

=item B<--critical-total-cache>

Threshold in percentage.

=item B<--warning-backend-latency>

Threshold in milliseconds.

=item B<--critical-backend-latency>

Threshold in milliseconds.

=item B<--warning-drive-latency>

Threshold in milliseconds.

=item B<--critical-drive-latency>

Threshold in milliseconds.

=item B<--warning-fc-iops>

Threshold in IOPS.

=item B<--critical-fc-iops>

Threshold in IOPS.

=item B<--warning-fc-bandwidth>

Threshold in bytes per second.

=item B<--critical-fc-bandwidth>

Threshold in bytes per second.

=item B<--warning-node-cpu>

Threshold in percentage.

=item B<--critical-node-cpu>

Threshold in percentage.

=back

=cut
