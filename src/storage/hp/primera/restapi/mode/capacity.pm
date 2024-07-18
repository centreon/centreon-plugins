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

package storage::hp::primera::restapi::mode::capacity;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub storage_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking storage '%s'",
        $options{instance_value}->{type}
    );
}

sub prefix_storage_output {
    my ($self, %options) = @_;

    return sprintf(
        "storage '%s' ",
        $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'storages', type => 3, cb_prefix_output => 'prefix_storage_output', cb_long_output => 'storage_long_output', indent_long_output => '    ', message_multiple => 'All storage capacities are ok',
            group => [
                { name => 'space', type => 0 },
                { name => 'efficiency', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{space} = [
        { label => 'space-usage', nlabel => 'storage.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'storage.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'storage.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-unavailable', nlabel => 'storage.space.unavailable.bytes', set => {
                key_values => [ { name => 'unavailable' } ],
                output_template => 'unavailable: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-failed', nlabel => 'storage.space.failed.bytes', set => {
                key_values => [ { name => 'failed' } ],
                output_template => 'failed: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', unit => 'B', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{efficiency} = [
        { label => 'compaction', nlabel => 'storage.space.compaction.ratio.count', set => {
                key_values => [ { name => 'compaction' } ],
                output_template => 'compaction: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'deduplication', nlabel => 'storage.space.deduplication.ratio.count', set => {
                key_values => [ { name => 'deduplication' } ],
                output_template => 'deduplication: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'compression', nlabel => 'storage.space.compression.ratio.count', set => {
                key_values => [ { name => 'compression' } ],
                output_template => 'compression: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'data-reduction', nlabel => 'storage.space.data_reduction.ratio.count', set => {
                key_values => [ { name => 'data_reduction' } ],
                output_template => 'data reduction: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'overprovisioning', nlabel => 'storage.space.overprovisioning.ratio.count', set => {
                key_values => [ { name => 'overprovisioning' } ],
                output_template => 'overprovisioning: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
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
        'filter-type:s' => { name => 'filter_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(
        endpoint => '/api/v1/capacity'
    );

    for my $type (keys %{$response}) {
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne ''
                && $type !~ /$self->{option_results}->{filter_type}/);

        my $total       = $response->{$type}->{totalMiB} * 1024 * 1024;
        my $free        = $response->{$type}->{freeMiB} * 1024 * 1024;
        my $unavailable = $response->{$type}->{unavailableCapacityMiB} * 1024 * 1024;
        my $failed      = $response->{$type}->{failedCapacityMiB} * 1024 * 1024;
        #my $allocated   = $response->{$type}->{allocated}->{totalAllocatedMiB} * 1024 * 1024;

        $self->{storages}->{$type} = {
            type  => $type,
            space => {
                total       => $total,
                free        => $free,
                used        => $total - $free,
                unavailable => $unavailable,
                prct_used   => ($total - $free) * 100 / $total,
                prct_free   => $free * 100 / $total,
                failed      => $failed
            }
        };

        my $shortcut = $response->{$type}->{allocated}->{volumes}->{capacityEfficiency};

        $self->{storages}->{$type}->{efficiency}->{compaction}          = $shortcut->{compaction}         if defined($shortcut->{compaction});
        $self->{storages}->{$type}->{efficiency}->{deduplication}       = $shortcut->{deduplication}      if defined($shortcut->{deduplication});
        $self->{storages}->{$type}->{efficiency}->{compression}         = $shortcut->{compression}        if defined($shortcut->{compression});
        $self->{storages}->{$type}->{efficiency}->{data_reduction}      = $shortcut->{dataReduction}      if defined($shortcut->{dataReduction});
        $self->{storages}->{$type}->{efficiency}->{overprovisioning}    = $shortcut->{overProvisioning}   if defined($shortcut->{overProvisioning});
    }

    if (scalar(keys %{$self->{storages}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Couldn't get capacity information");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check storage capacity per storage type.

=over 8

=item B<--filter-type>

Filter storage by type (regular expression).
The known types are: allCapacity, FCCapacity, SSDCapacity and NLCapacity.

=item B<--warning-*> B<--critical-*>

Thresholds that can apply to:
- Space oriented metrics: 'space-usage', 'space-usage-free', 'space-usage-prct', 'space-unavailable', 'space-failed',
- Storage optimization metrics: 'compaction', 'deduplication', 'compression', 'data-reduction', 'overprovisioning'.

=back

=cut
