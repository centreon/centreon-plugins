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

package storage::netapp::ontap::restapi::mode::volumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'state: ' . $self->{result_values}->{state};
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($provisioned_size_value, $provisioned_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_provisioned_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    return sprintf(
        'space usage total: %s provisioned: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $provisioned_size_value . " " . $provisioned_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub custom_virtual_usage_output {
    my ($self, %options) = @_;
    
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{virtual_used_space});
    return sprintf(
        'virtual space usage used: %s (%.2f%%)',
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{virtual_prct_used_space},
    );
}

sub custom_logical_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_logical_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{logical_used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{logical_free_space});
    return sprintf(
        'logical space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{logical_prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{logical_prct_free_space}
    );
}

sub custom_snapshot_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_snapshot_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{snapshot_used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{snapshot_free_space});
    return sprintf(
        'snapshot reserved size: %s used: %s (%.2f%%) reserve available: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{snapshot_prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{snapshot_prct_free_space}
    );
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return "Volume '" . $options{instance_value}->{display} . "' ";
}

sub skip_logical {
    my ($self, %options) = @_;

    return (defined($self->{add_logical}) ? 0 : 1);
}

sub skip_snapshot {
    my ($self, %options) = @_;

    return (defined($self->{add_snapshot}) ? 0 : 1);
}

sub skip_virtual {
    my ($self, %options) = @_;

    return (defined($self->{add_virtual}) ? 0 : 1);
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'volumes', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All volumes are ok' },
        { name => 'logical', type => 1, cb_prefix_output => 'prefix_volume_output', cb_init => 'skip_logical' },
        { name => 'snapshots', type => 1, cb_prefix_output => 'prefix_volume_output', cb_init => 'skip_snapshot' },
        { name => 'virtual', type => 1, cb_prefix_output => 'prefix_volume_output', cb_init => 'skip_virtual' }

    ];
    
    $self->{maps_counters}->{volumes} = [
        { label => 'status', type => 2, critical_default => '%{state} !~ /online/i', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'volume.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, 
                                { name => 'total_space' }, { name => 'total_provisioned_space' }, { name => 'display' } 
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'volume.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, 
                                { name => 'total_provisioned_space' }, { name => 'total_space' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'volume.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, 
                                { name => 'total_space' }, { name => 'total_provisioned_space' },{ name => 'display' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read', nlabel => 'volume.io.read.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'read' } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write', nlabel => 'volume.io.write.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'write' } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'other', nlabel => 'volume.io.other.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'other' } ],
                output_template => 'other: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'total', nlabel => 'volume.io.total.usage.bytespersecond', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-iops', nlabel => 'volume.io.read.usage.iops', set => {
                key_values => [ { name => 'read_iops' } ],
                output_template => 'read iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'volume.io.write.usage.iops', set => {
                key_values => [ { name => 'write_iops' } ],
                output_template => 'write iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'other-iops', nlabel => 'volume.io.other.usage.iops', set => {
                key_values => [ { name => 'other_iops' } ],
                output_template => 'other iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'total-iops', nlabel => 'volume.io.total.usage.iops', set => {
                key_values => [ { name => 'total_iops' } ],
                output_template => 'total iops: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-latency', nlabel => 'volume.io.read.latency.milliseconds', set => {
                key_values => [ { name => 'read_latency' } ],
                output_template => 'read latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-latency', nlabel => 'volume.io.write.latency.milliseconds', set => {
                key_values => [ { name => 'write_latency' } ],
                output_template => 'write latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'other-latency', nlabel => 'volume.io.other.latency.milliseconds', set => {
                key_values => [ { name => 'other_latency' } ],
                output_template => 'other latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'total-latency', nlabel => 'volume.io.total.latency.milliseconds', set => {
                key_values => [ { name => 'total_latency' } ],
                output_template => 'total latency: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{virtual} = [
        { label => 'virtual-usage', nlabel => 'volume.virtualspace.usage.bytes', set => {
                key_values => [ { name => 'virtual_used_space' }, { name => 'virtual_prct_used_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_virtual_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'virtual-usage-prct', nlabel => 'volume.virtualspace.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'virtual_prct_used_space' }, { name => 'virtual_used_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_virtual_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{logical} = [
        { label => 'logical-usage', nlabel => 'volume.logicalspace.usage.bytes', set => {
                    key_values => [ { name => 'logical_used_space' }, { name => 'logical_free_space' }, { name => 'logical_prct_used_space' }, { name => 'logical_prct_free_space' }, { name => 'total_logical_space' }, { name => 'display' },  ],
                    closure_custom_output => $self->can('custom_logical_usage_output'),
                    perfdatas => [
                        { template => '%d', min => 0, max => 'total_logical_space',
                        unit => 'B', cast_int => 1, label_extra_instance => 1 }
                    ]
            }
        },
        { label => 'logical-usage-free', nlabel => 'volume.logicalspace.free.bytes', set => {
                key_values => [ { name => 'logical_free_space' }, { name => 'logical_used_space' }, { name => 'logical_prct_used_space' }, { name => 'logical_prct_free_space' }, { name => 'total_logical_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_logical_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_logical_space',
                    unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'logical-usage-prct', nlabel => 'volume.logicalspace.usage.percentage', set => {
                key_values => [ { name => 'logical_prct_used_space' }, { name => 'logical_used_space' }, { name => 'logical_free_space' }, { name => 'logical_prct_free_space' }, { name => 'total_logical_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_logical_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100,
                    unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{snapshots} = [
        { label => 'snapshot-usage', nlabel => 'volume.space.snapshot.usage.bytes', set => {
                    key_values => [ { name => 'snapshot_used_space' }, { name => 'snapshot_free_space' }, { name => 'snapshot_prct_used_space' }, { name => 'snapshot_prct_free_space' }, { name => 'total_snapshot_space' }, { name => 'display' },  ],
                    closure_custom_output => $self->can('custom_snapshot_usage_output'),
                    perfdatas => [
                        { template => '%d', min => 0, max => 'total_snapshot_space',
                        unit => 'B', cast_int => 1, label_extra_instance => 1 }
                    ]
            }
        },
        { label => 'snapshot-usage-free', nlabel => 'volume.space.snapshot.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'snapshot_free_space' }, { name => 'snapshot_used_space' }, { name => 'snapshot_prct_used_space' }, { name => 'snapshot_prct_free_space' }, { name => 'total_snapshot_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_snapshot_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_snapshot_space',
                    unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'snapshot-usage-prct', nlabel => 'volume.space.snapshot.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'snapshot_prct_used_space' }, { name => 'snapshot_used_space' }, { name => 'snapshot_free_space' }, { name => 'snapshot_prct_free_space' }, { name => 'total_snapshot_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_snapshot_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100,
                    unit => '%', label_extra_instance => 1 }
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
        'filter-volume-name:s'  => { name => 'filter_volume_name' },
        'filter-name:s'         => { name => 'filter_name' },
        'filter-vserver-name:s' => { name => 'filter_vserver_name' },
        'add-snapshot'          => { name => 'add_snapshot' },
        'add-virtual'           => { name => 'add_virtual' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{filter_volume_name}) && $self->{option_results}->{filter_volume_name} ne '') {
        $self->{add_logical} = 1;
    }

    if (defined($self->{option_results}->{add_snapshot})) {
        $self->{add_snapshot} = 1;
    }

    if (defined($self->{option_results}->{add_virtual})) {
        $self->{add_virtual} = 1;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $endpoint = '/api/storage/volumes?fields=svm,name,state,space,metric';
    
    if (defined($self->{option_results}->{filter_volume_name}) && $self->{option_results}->{filter_volume_name} ne '' ) {
        $endpoint .= '&name=' . $self->{option_results}->{filter_volume_name};
    }

    my $volumes = $options{custom}->request_api(endpoint => $endpoint);

    $self->{volumes} = {};
    $self->{snapshot} = {};
    $self->{logical} = {};
    $self->{virtual} = {};
    foreach (@{$volumes->{records}}) {
        my $name = defined($_->{svm}) && $_->{svm}->{name} ne '' ?
            $_->{svm}->{name} . ':' . $_->{name} :
            $_->{name};
        if (defined($self->{option_results}->{filter_vserver_name}) && $self->{option_results}->{filter_vserver_name} ne '' &&
            defined($_->{svm}) && $_->{svm}->{name} ne '' &&  $_->{svm}->{name} !~ /$self->{option_results}->{filter_vserver_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $_->{svm}->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping volume '" . $_->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{volumes}->{$name} = {
            display => $name,
            state => $_->{state},

            total_space             => $_->{space}->{afs_total},
            total_provisioned_space => $_->{space}->{size},
            used_space              => $_->{space}->{used_by_afs},
            free_space              => $_->{space}->{available},
            prct_used_space         => (defined($_->{space}->{afs_total}) && $_->{space}->{afs_total} > 0) ? (($_->{space}->{afs_total} - $_->{space}->{available}) * 100 / $_->{space}->{afs_total}) : undef,
            prct_free_space         => $_->{space}->{available_percent},

            read          => $_->{metric}->{throughput}->{read},
            write         => $_->{metric}->{throughput}->{write},
            other         => $_->{metric}->{throughput}->{other},
            total         => $_->{metric}->{throughput}->{total},
            read_iops     => $_->{metric}->{iops}->{read},
            write_iops    => $_->{metric}->{iops}->{write},
            other_iops    => $_->{metric}->{iops}->{other},
            total_iops    => $_->{metric}->{iops}->{total},
            read_latency  => (defined($_->{metric}->{latency}->{read})) ? ($_->{metric}->{latency}->{read} / 1000) : undef,
            write_latency => (defined($_->{metric}->{latency}->{write})) ? ($_->{metric}->{latency}->{write} / 1000) : undef,
            other_latency => (defined($_->{metric}->{latency}->{other})) ? ($_->{metric}->{latency}->{other} / 1000) : undef,
            total_latency => (defined($_->{metric}->{latency}->{total})) ? ($_->{metric}->{latency}->{total} / 1000) : undef,
        };

        if (defined($self->{add_virtual})) {
            $self->{virtual}->{$name} = {
                display                  => $name,
                virtual_used_space      => $_->{space}->{used},
                virtual_prct_used_space => $_->{space}->{percent_used}
            };
        }

        if (defined($self->{add_snapshot}) && defined($_->{space}->{snapshot})) {
            $self->{snapshots}->{$name} = {
                display                  => $name,
                total_snapshot_space     => $_->{space}->{snapshot}->{reserve_size},
                snapshot_used_space      => $_->{space}->{snapshot}->{used},
                snapshot_free_space      => $_->{space}->{snapshot}->{reserve_available},
                snapshot_prct_used_space =>  $_->{space}->{snapshot}->{space_used_percent},
                snapshot_prct_free_space => 100 - $_->{space}->{snapshot}->{space_used_percent}
            };
        }

        if (defined($self->{add_logical}) && defined($_->{space}->{logical_space})) {
            $self->{logical}->{$name} = {
                display                 => $name,
                total_logical_space     => $_->{space}->{logical_space}->{used} + $_->{space}->{logical_space}->{available},
                logical_used_space      => $_->{space}->{logical_space}->{used},
                logical_free_space      => $_->{space}->{logical_space}->{available},
                logical_prct_used_space =>  $_->{space}->{logical_space}->{used_percent},
                logical_prct_free_space => 100 - $_->{space}->{logical_space}->{used_percent}
            };
        }    
    }

    if (scalar(keys %{$self->{volumes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No volume found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check volumes.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: C<--filter-counters='^usage$'>.

=item B<--filter-volume-name>

Filter the API request by volumes name (* can be used, volumes name are separated by |). Required if you wan to retrieve 
logical space metrics.

=item B<--filter-name>

Filter the API request result by volume name (can be a regexp).

=item B<--filter-vserver-name>

Filter volumes by Vserver name (can be a regexp).


=item B<--add-virtual>

Add virtual usage information.

=item B<--add-snapshot>

Add snapshot information.


=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{display}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{display}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} !~ /online/i').
You can use the following variables: %{state}, %{display}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: usage' (B), usage-free (B), usage-prct (%),
virtual-usage' (B), virtual-usage-prct (%),
logical-usage (B), logical-usage-free (B), logical-usage-prct (%),
snapshot-usage (B), snapshot-usage-free (B), snapshot-usage-prct (%),
read (B/s), read-iops, write (B/s), write-iops,
read-latency (ms), write-latency (ms), total-latency (ms),
other-latency (ms), other (B/s), total (B/s),
other-iops, total-iops.

=back

=cut
