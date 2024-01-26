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

package storage::netapp::ontap::oncommandapi::mode::volumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_iops_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [
            $self->{result_values}->{svmName},
            $self->{result_values}->{volumeName}
        ],
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_latency_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [
            $self->{result_values}->{svmName},
            $self->{result_values}->{volumeName}
        ],
        unit => 'ms',
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_space_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [
            $self->{result_values}->{svmName},
            $self->{result_values}->{volumeName}
        ],
        unit => 'B',
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{total_space}
    );
}

sub custom_prct_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [
            $self->{result_values}->{svmName},
            $self->{result_values}->{volumeName}
        ],
        unit => '%',
        value => sprintf('%.2f', $self->{result_values}->{ $self->{key_values}->[0]->{name} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => 100
    );
}

sub custom_space_usage_output {
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

sub volume_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking '%s' [svm: %s]",
        $options{instance_value}->{volumeName}, 
        $options{instance_value}->{svmName}
    );
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return sprintf(
        "volume '%s' [svm: %s] ",
        $options{instance_value}->{volumeName}, 
        $options{instance_value}->{svmName}
    );
}

sub prefix_iops_output {
    my ($self, %options) = @_;

    return 'iops ';
}

sub prefix_latency_output {
    my ($self, %options) = @_;

    return 'latency ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'volumes', type => 3, cb_prefix_output => 'prefix_volume_output', cb_long_output => 'volume_long_output',
          indent_long_output => '    ', message_multiple => 'All volumes are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'space', type => 0, skipped_code => { -10 => 1 } },
                { name => 'inodes', type => 0, skipped_code => { -10 => 1 } },
                { name => 'other', type => 0, skipped_code => { -10 => 1 } },
                { name => 'iops', type => 0, cb_prefix_output => 'prefix_iops_output', skipped_code => { -10 => 1 } },
                { name => 'latency', type => 0, cb_prefix_output => 'prefix_latency_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{state} !~ /online/i',
            set => {
                key_values => [ { name => 'state' }, { name => 'volumeName' }, { name => 'svmName' } ],
                output_template => "state: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{space} = [
         { label => 'space-usage', nlabel => 'volume.space.usage.bytes', set => {
                key_values => [
                    { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' },
                    { name => 'volumeName' }, { name => 'svmName' }
                ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                closure_custom_perfdata => $self->can('custom_space_perfdata')
            }
        },
        { label => 'space-usage-free', nlabel => 'volume.space.free.bytes', display_ok => 0, set => {
                key_values => [
                    { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' },
                    { name => 'volumeName' }, { name => 'svmName' }
                ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                closure_custom_perfdata => $self->can('custom_space_perfdata')
            }
        },
        { label => 'space-usage-prct', nlabel => 'volume.space.usage.percentage', display_ok => 0, set => {
                key_values => [
                    { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, { name => 'total_space' },
                    { name => 'volumeName' }, { name => 'svmName' }
                ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                closure_custom_perfdata => $self->can('custom_prct_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{inodes} = [
        { label => 'inodes-usage-prct', nlabel => 'volume.inodes.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'volumeName' }, { name => 'svmName' } ],
                output_template => 'inodes used %.2f %%',
                closure_custom_perfdata => $self->can('custom_prct_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{other} = [
        { label => 'compression-saved-prct', nlabel => 'volume.space.compression.saved.percentage', set => {
                key_values => [ { name => 'compression' }, { name => 'volumeName' }, { name => 'svmName' } ],
                output_template => 'compression space saved %.2f %%',
                closure_custom_perfdata => $self->can('custom_prct_perfdata')
            }
        },
        { label => 'deduplication-saved-prct', nlabel => 'volume.space.deduplication.saved.percentage', set => {
                key_values => [ { name => 'deduplication' }, { name => 'volumeName' }, { name => 'svmName' } ],
                output_template => 'deduplication space saved %.2f %%',
                closure_custom_perfdata => $self->can('custom_prct_perfdata')
            }
        },
        { label => 'snapshots-reserve-usage-prct', nlabel => 'volume.snapshots.reserve.usage.percentage', set => {
                key_values => [ { name => 'snapshot_reserve_used' }, { name => 'volumeName' }, { name => 'svmName' } ],
                output_template => 'snapshots reserve used %.2f %%',
                closure_custom_perfdata => $self->can('custom_prct_perfdata')
            }
        },
    ];

    $self->{maps_counters}->{iops} = [
        { label => 'read-iops', nlabel => 'volume.io.read.usage.iops', set => {
                key_values => [ { name => 'read' }, { name => 'volumeName' }, { name => 'svmName' } ],
                output_template => 'read %s',
                closure_custom_perfdata => $self->can('custom_iops_perfdata')
            }
        },
        { label => 'write-iops', nlabel => 'volume.io.write.usage.iops', set => {
                key_values => [ { name => 'write' }, { name => 'volumeName' }, { name => 'svmName' } ],
                output_template => 'write %s',
                closure_custom_perfdata => $self->can('custom_iops_perfdata')
            }
        },
        { label => 'other-iops', nlabel => 'volume.io.other.usage.iops', set => {
                key_values => [ { name => 'other' }, { name => 'volumeName' }, { name => 'svmName' } ],
                output_template => 'other %s',
                closure_custom_perfdata => $self->can('custom_iops_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{latency} = [
        { label => 'average-latency', nlabel => 'volume.io.average.latency.milliseconds', set => {
                key_values => [ { name => 'avg' }, { name => 'volumeName' }, { name => 'svmName' } ],
                output_template => 'average %s ms',
                closure_custom_perfdata => $self->can('custom_latency_perfdata')
            }
        },
        { label => 'read-latency', nlabel => 'volume.io.read.latency.milliseconds', set => {
                key_values => [ { name => 'read' }, { name => 'volumeName' }, { name => 'svmName' } ],
                output_template => 'read %s ms',
                closure_custom_perfdata => $self->can('custom_latency_perfdata')
            }
        },
        { label => 'write-latency', nlabel => 'volume.io.write.latency.milliseconds', set => {
                key_values => [ { name => 'write' }, { name => 'volumeName' }, { name => 'svmName' } ],
                output_template => 'write %s ms',
                closure_custom_perfdata => $self->can('custom_latency_perfdata')
            }
        },
        { label => 'other-latency', nlabel => 'volume.io.other.latency.milliseconds', set => {
                key_values => [ { name => 'other' }, { name => 'volumeName' }, { name => 'svmName' } ],
                output_template => 'other %s ms',
                closure_custom_perfdata => $self->can('custom_latency_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-volume-key:s'   => { name => 'filter_volume_key' },
        'filter-volume-name:s'  => { name => 'filter_volume_name' },
        'filter-volume-state:s' => { name => 'filter_volume_state' },
        'filter-volume-style:s' => { name => 'filter_volume_style' },
        'filter-volume-type:s'  => { name => 'filter_volume_type' },
        'filter-svm-name:s'     => { name => 'filter_svm_name' },
        'add-metrics'           => { name => 'add_metrics' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $svms = $options{custom}->get(path => '/storage-vms');
    my $volumes = $options{custom}->get(path => '/volumes');

    $self->{volumes} = {};
    foreach my $volume (@$volumes) {
        next if (defined($self->{option_results}->{filter_volume_key}) && $self->{option_results}->{filter_volume_key} ne '' &&
            $volume->{key} !~ /$self->{option_results}->{filter_volume_key}/);
        next if (defined($self->{option_results}->{filter_volume_name}) && $self->{option_results}->{filter_volume_name} ne '' &&
            $volume->{name} !~ /$self->{option_results}->{filter_volume_name}/);
        next if (defined($self->{option_results}->{filter_volume_state}) && $self->{option_results}->{filter_volume_state} ne '' &&
            $volume->{state} !~ /$self->{option_results}->{filter_volume_state}/);
        next if (defined($self->{option_results}->{filter_volume_style}) && $self->{option_results}->{filter_volume_style} ne '' &&
            $volume->{style} !~ /$self->{option_results}->{filter_volume_style}/);
        next if (defined($self->{option_results}->{filter_volume_type}) && $self->{option_results}->{filter_volume_type} ne '' &&
            $volume->{vol_type} !~ /$self->{option_results}->{filter_volume_type}/);

        my $svm_name = $options{custom}->get_record_attr(records => $svms, key => 'key', value => $volume->{storage_vm_key}, attr => 'name');
        $svm_name = 'root' if (!defined($svm_name));

        next if (defined($self->{option_results}->{filter_svm_name}) && $self->{option_results}->{filter_svm_name} ne '' &&
            $svm_name !~ /$self->{option_results}->{filter_svm_name}/);

        $self->{volumes}->{ $volume->{key} } = {
            volumeName => $volume->{name},
            svmName => $svm_name,
            status => {
                volumeName => $volume->{name},
                svmName => $svm_name,
                state => defined($volume->{state}) ? $volume->{state} : 'none'
            },
            space => {
                volumeName => $volume->{name},
                svmName => $svm_name,
                total_space => $volume->{size_total},
                used_space => $volume->{size_used},
                free_space => $volume->{size_total} - $volume->{size_used},
                prct_used_space => $volume->{size_used} * 100 / $volume->{size_total},
                prct_free_space => 100 - ($volume->{size_used} * 100 / $volume->{size_total})
            },
            inodes => {
                volumeName => $volume->{name},
                svmName => $svm_name,
                prct_used => $volume->{inode_files_used} * 100 / $volume->{inode_files_total}
            },
            other => {
                volumeName => $volume->{name},
                svmName => $svm_name,
                compression => $volume->{percentage_compression_space_saved},
                deduplication => $volume->{percentage_deduplication_space_saved},
                snapshot_reserve_used => $volume->{percentage_snapshot_reserve_used}
            },
            iops => {
                volumeName => $volume->{name},
                svmName => $svm_name
            },
            latency => {
                volumeName => $volume->{name},
                svmName => $svm_name
            }
        };

        if (defined($self->{option_results}->{add_metrics})) {
            my $metrics = $options{custom}->get(
                path => '/volumes/metrics',
                get_param => [
                    'resource_key=' . $volume->{key},
                    'name=read_ops',
                    'name=write_ops',
                    'name=other_ops',
                    'name=avg_latency',
                    'name=read_latency',
                    'name=write_latency',
                    'name=other_latency'
                ]
            );
    
            foreach my $metric (@{$metrics->[0]->{metrics}}) {
                $self->{volumes}->{ $volume->{key} }->{iops}->{read} = sprintf('%.2f', $metric->{samples}->[0]->{value}) if ($metric->{name} eq 'read_ops');
                $self->{volumes}->{ $volume->{key} }->{iops}->{write} = sprintf('%.2f', $metric->{samples}->[0]->{value}) if ($metric->{name} eq 'write_ops');
                $self->{volumes}->{ $volume->{key} }->{iops}->{other} = sprintf('%.2f', $metric->{samples}->[0]->{value}) if ($metric->{name} eq 'other_ops');
                
                $self->{volumes}->{ $volume->{key} }->{latency}->{avg} = sprintf('%.2f', $metric->{samples}->[0]->{value} / 1000) if ($metric->{name} eq 'avg_latency');
                $self->{volumes}->{ $volume->{key} }->{latency}->{read} = sprintf('%.2f', $metric->{samples}->[0]->{value} / 1000) if ($metric->{name} eq 'read_latency');
                $self->{volumes}->{ $volume->{key} }->{latency}->{write} = sprintf('%.2f', $metric->{samples}->[0]->{value} / 1000) if ($metric->{name} eq 'write_latency');
                $self->{volumes}->{ $volume->{key} }->{latency}->{other} = sprintf('%.2f', $metric->{samples}->[0]->{value} / 1000) if ($metric->{name} eq 'other_latency');
            }
        }
    }
}

1;

__END__

=head1 MODE

Check volumes.

=over 8

=item B<--add-metrics>

Add IOPS and latency metrics.

=item B<--filter-volume-key>

Filter volumes by volume key.

=item B<--filter-volume-name>

Filter volumes by volume name.

=item B<--filter-volume-state>

Filter volumes by volume state.

=item B<--filter-volume-style>

Filter volumes by volume style.

=item B<--filter-volume-type>

Filter volumes by volume type.

=item B<--filter-svm-name>

Filter volumes by storage virtual machine name.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{volumeName}, %{svmName}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{volumeName}, %{svmName}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} !~ /online/i').
You can use the following variables: %{state}, %{volumeName}, %{svmName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'inodes-usage-prct', 'space-usage', 'space-usage-free', 'space-usage-prct',
'read-iops', 'write-iops', 'other-iops', 
'average-latency', 'read-latency' 'write-latency,' 'other-latency',
'compression-saved-prct', 'deduplication-saved-prct', 'snapshots-reserve-usage-prct'.

=back

=cut
