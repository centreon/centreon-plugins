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

package storage::netapp::ontap::restapi::mode::aggregates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'state: ' . $self->{result_values}->{state};
}

sub aggregates_long_output {
    my ($self, %options) = @_;

    return "checking aggregates '" . $options{instance_value}->{display} . "'";
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub prefix_aggregates_output {
    my ($self, %options) = @_;

    return "Aggregates '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'aggregates', type => 1, cb_prefix_output => 'prefix_aggregates_output', message_multiple => 'All aggregates are ok' }
    ];

    $self->{maps_counters}->{aggregates} = [
        { label => 'status', type => 2, critical_default => '%{state} !~ /online/i', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'aggregate.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'used_space', template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-free', nlabel => 'aggregate.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'free_space', template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-prct', nlabel => 'aggregate.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'display' } ],
                output_template => 'used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used_space', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read', nlabel => 'aggregate.io.read.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'read' } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'aggregate.io.write.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'write' } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'other', nlabel => 'aggregate.io.other.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'other' } ],
                output_template => 'other: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'total', nlabel => 'aggregate.io.total.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-iops', nlabel => 'aggregate.io.read.usage.iops', set => {
                key_values => [ { name => 'read_iops' } ],
                output_template => 'read iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'aggregate.io.write.usage.iops', set => {
                key_values => [ { name => 'write_iops' } ],
                output_template => 'write iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'other-iops', nlabel => 'aggregate.io.other.usage.iops', set => {
                key_values => [ { name => 'other_iops' } ],
                output_template => 'other iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'total-iops', nlabel => 'aggregate.io.total.usage.iops', set => {
                key_values => [ { name => 'total_iops' } ],
                output_template => 'total iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-latency', nlabel => 'aggregate.io.read.latency.microseconds', set => {
                key_values => [ { name => 'read_latency' } ],
                output_template => 'read latency: %s µs',
                perfdatas => [
                    { template => '%s', unit => 'µs', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-latency', nlabel => 'aggregate.io.write.latency.microseconds', set => {
                key_values => [ { name => 'write_latency' } ],
                output_template => 'write latency: %s µs',
                perfdatas => [
                    { template => '%s', unit => 'µs', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'other-latency', nlabel => 'aggregate.io.other.latency.microseconds', set => {
                key_values => [ { name => 'other_latency' } ],
                output_template => 'other latency: %s µs',
                perfdatas => [
                    { template => '%s', unit => 'µs', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'total-latency', nlabel => 'aggregate.io.total.latency.microseconds', set => {
                key_values => [ { name => 'total_latency' } ],
                output_template => 'total latency: %s µs',
                perfdatas => [
                    { template => '%s', unit => 'µs', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'  => { name => 'filter_name' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $aggregates = $options{custom}->request_api(endpoint => '/api/storage/aggregates?fields=name,uuid,state,space');

    $self->{aggregates} = {};
    foreach (@{$aggregates->{records}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $_->{name} !~ /$self->{option_results}->{filter_name}/);
        my $name = $_->{name};
        my $uuid = $_->{uuid};

        my $agg = $options{custom}->request_api(endpoint => '/api/storage/aggregates/'.$uuid.'?fields=metric');

        $self->{aggregates}->{$name} = {
            display => $name,
            state => $_->{state},
            total_space => $_->{space}->{block_storage}->{size},
            used_space => $_->{space}->{block_storage}->{used},
            free_space => $_->{space}->{block_storage}->{available},
            prct_used_space =>
                ($_->{space}->{block_storage}->{used} * 100 / $_->{space}->{block_storage}->{size}),
            prct_free_space =>
                ($_->{space}->{block_storage}->{available} * 100 / $_->{space}->{block_storage}->{size}),
            read          => $agg->{metric}->{throughput}->{read},
            write         => $agg->{metric}->{throughput}->{write},
            other         => $agg->{metric}->{throughput}->{other},
            total         => $agg->{metric}->{throughput}->{total},
            read_iops     => $agg->{metric}->{iops}->{read},
            write_iops    => $agg->{metric}->{iops}->{write},
            other_iops    => $agg->{metric}->{iops}->{other},
            total_iops    => $agg->{metric}->{iops}->{total},
            read_latency  => $agg->{metric}->{latency}->{read},
            write_latency => $agg->{metric}->{latency}->{write},
            other_latency => $agg->{metric}->{latency}->{other},
            total_latency => $agg->{metric}->{latency}->{total}
        };
    }

    if (scalar(keys %{$self->{aggregates}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No aggregate found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check aggregates.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^usage$'

=item B<--filter-name>

Filter aggregates by aggregate name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{display}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} !~ /online/i').
You can use the following variables: %{state}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%),
'read' (B/s), 'read-iops', 'write' (B/s), 'write-iops',
'read-latency' (ms), 'write-latency' (ms), 'total-latency' (ms),
'other-latency' (ms), 'other' (B/s), 'total' (B/s),
'other-iops', 'total-iops'.

=back

=cut
