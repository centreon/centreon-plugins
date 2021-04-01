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

package storage::netapp::ontap::oncommandapi::mode::volumeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => 'used', unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                              { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    
    my $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", 
            $total_value . " " . $total_unit, 
            $used_value . " " . $used_unit, $self->{result_values}->{prct_used}, 
            $free_value . " " . $free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_size_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_size_used'};

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    } else {
        $self->{result_values}->{free} = '0';
        $self->{result_values}->{prct_used} = '0';
        $self->{result_values}->{prct_free} = '0';
    }

    return 0;
}

sub custom_inode_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'inodes', unit => '%',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => sprintf("%.2f", $self->{result_values}->{prct_used}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0, max => 100
    );
}

sub custom_inode_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used},
                                                  threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                                 { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_inode_output {
    my ($self, %options) = @_;
    
   my $msg = sprintf("Inodes Used: %.2f%%", $self->{result_values}->{prct_used});
    return $msg;
}

sub custom_inode_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_inode_files_used'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_inode_files_total'};

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    } else {
        $self->{result_values}->{prct_used} = '0';
    }

    return 0;
}

sub custom_snapshot_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'snapshot', unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_snapshot_threshold {
    my ($self, %options) = @_;
    
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                              { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_snapshot_output {
    my ($self, %options) = @_;
    
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my ($reserved_value, $reserved_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{reserved});
    
    my $msg = sprintf("Snapshot Used: %s (%.2f%%) Free: %s (%.2f%%) Reserved: %s",
            $used_value . " " . $used_unit, $self->{result_values}->{prct_used},
            $free_value . " " . $free_unit, $self->{result_values}->{prct_free},
            $reserved_value . " " . $reserved_unit);
    return $msg;
}

sub custom_snapshot_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_size_available_for_snapshot'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_size_used_by_snapshots'};
    $self->{result_values}->{reserved} = $options{new_datas}->{$self->{instance} . '_snapshot_reserve_size'};

    $self->{result_values}->{total} = $self->{result_values}->{used} + $self->{result_values}->{free};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub custom_compression_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'compresssaved', unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total});
}

sub custom_compression_threshold {
    my ($self, %options) = @_;
    
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                              { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_compression_output {
    my ($self, %options) = @_;
    
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    
    my $msg = sprintf("Compression Space Saved: %s (%.2f%%)",
            $used_value . " " . $used_unit, $self->{result_values}->{prct_used});
    return $msg;
}

sub custom_compression_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_size_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_compression_space_saved'};

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    } else {
        $self->{result_values}->{free} = '0';
        $self->{result_values}->{prct_used} = '0';
        $self->{result_values}->{prct_free} = '0';
    }

    return 0;
}

sub custom_deduplication_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'dedupsaved', unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_deduplication_threshold {
    my ($self, %options) = @_;
    
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                              { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_deduplication_output {
    my ($self, %options) = @_;
    
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    
    my $msg = sprintf("Deduplication Space Saved: %s (%.2f%%)",
            $used_value . " " . $used_unit, $self->{result_values}->{prct_used});
    return $msg;
}

sub custom_deduplication_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_size_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_deduplication_space_saved'};

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    } else {
        $self->{result_values}->{free} = '0';
        $self->{result_values}->{prct_used} = '0';
        $self->{result_values}->{prct_free} = '0';
    }

    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Volume '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'volumes', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All volumes usage are ok' },
    ];
    
    $self->{maps_counters}->{volumes} = [
        { label => 'usage', set => {
                key_values => [ { name => 'size_used' }, { name => 'size_total' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'inodes', set => {
                key_values => [ { name => 'inode_files_used' }, { name => 'inode_files_total' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_inode_calc'),
                closure_custom_output => $self->can('custom_inode_output'),
                closure_custom_perfdata => $self->can('custom_inode_perfdata'),
                closure_custom_threshold_check => $self->can('custom_inode_threshold'),
            }
        },
        { label => 'snapshot', set => {
                key_values => [ { name => 'size_available_for_snapshot' }, { name => 'size_used_by_snapshots' }, { name => 'snapshot_reserve_size' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_snapshot_calc'),
                closure_custom_output => $self->can('custom_snapshot_output'),
                closure_custom_perfdata => $self->can('custom_snapshot_perfdata'),
                closure_custom_threshold_check => $self->can('custom_snapshot_threshold'),
            }
        },
        { label => 'compresssaved', set => {
                key_values => [ { name => 'compression_space_saved' }, { name => 'size_total' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_compression_calc'),
                closure_custom_output => $self->can('custom_compression_output'),
                closure_custom_perfdata => $self->can('custom_compression_perfdata'),
                closure_custom_threshold_check => $self->can('custom_compression_threshold'),
            }
        },
        { label => 'dedupsaved', set => {
                key_values => [ { name => 'deduplication_space_saved' }, { name => 'size_total' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_deduplication_calc'),
                closure_custom_output => $self->can('custom_deduplication_output'),
                closure_custom_perfdata => $self->can('custom_deduplication_perfdata'),
                closure_custom_threshold_check => $self->can('custom_deduplication_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'  => { name => 'filter_name' },
        'filter-state:s' => { name => 'filter_state' },
        'filter-style:s' => { name => 'filter_style' },
        'filter-type:s'  => { name => 'filter_type' },
        'units:s'        => { name => 'units', default => '%' },
        'free'           => { name => 'free' }
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get(path => '/volumes');

    foreach my $volume (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $volume->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $volume->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
            $volume->{state} !~ /$self->{option_results}->{filter_state}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $volume->{name} . "': no matching filter state : '" . $volume->{state} . "'", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_style}) && $self->{option_results}->{filter_style} ne '' &&
            $volume->{style} !~ /$self->{option_results}->{filter_style}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $volume->{name} . "': no matching filter style : '" . $volume->{style} . "'", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $volume->{vol_type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $volume->{name} . "': no matching filter type : '" . $volume->{vol_type} . "'", debug => 1);
            next;
        }

        $self->{volumes}->{$volume->{key}} = {
            name => $volume->{name},
            size_total => $volume->{size_total},
            size_used => $volume->{size_used},
            compression_space_saved => $volume->{compression_space_saved},
            deduplication_space_saved => $volume->{deduplication_space_saved},
            size_available_for_snapshot => $volume->{size_available_for_snapshot},
            size_used_by_snapshots => $volume->{size_used_by_snapshots},
            snapshot_reserve_size => $volume->{snapshot_reserve_size},
            inode_files_used => $volume->{inode_files_used},
            inode_files_total => $volume->{inode_files_total},
        }
    }

    if (scalar(keys %{$self->{volumes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check NetApp volumes usage (space, inodes, snapshot, compression and deduplication)

=over 8

=item B<--filter-*>

Filter volume.
Can be: 'name', 'state', 'style', 'type' (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'usage', 'inodes', 'snapshot', 'compresssaved', 'dedupsaved'.

=item B<--critical-*>

Threshold critical.
Can be: 'usage', 'inodes', 'snapshot', 'compresssaved', 'dedupsaved'.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=back

=cut
