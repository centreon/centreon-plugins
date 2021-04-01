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

package storage::avid::isis::snmp::mode::usage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{allocated};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => $label, unit => 'B',
                                  value => $value_perf,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  min => 0, max => $self->{result_values}->{allocated});
    
    $self->{output}->perfdata_add(label => 'allocated', unit => 'B',
                                  value => $self->{result_values}->{allocated},
                                  min => 0, max => $self->{result_values}->{total});
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
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                                                         { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my $msg;
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_allocated_value, $total_allocated_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{allocated});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    $msg = sprintf("Total: %s Allocated: %s (%.2f%%) Used: %s (%.2f%%) Free: %s (%.2f%%)",
                $total_size_value . " " . $total_size_unit,
                $total_allocated_value . " " . $total_allocated_unit, $self->{result_values}->{prct_allocated},,
                $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_TotalSystemMB'}  * 1024 * 1024;
    $self->{result_values}->{allocated} = $options{new_datas}->{$self->{instance} . '_TotalAllocatedMB'}  * 1024 * 1024;
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_TotalUsedMB'}  * 1024 * 1024;

    $self->{result_values}->{prct_allocated} = $self->{result_values}->{allocated} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{allocated};

    $self->{result_values}->{free} = $self->{result_values}->{allocated} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'usage', set => {
                key_values => [ { name => 'TotalSystemMB' }, { name => 'TotalAllocatedMB' }, { name => 'TotalUsedMB' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'workspace-count', set => {
                key_values => [ { name => 'WorkspaceCount' } ],
                output_template => 'Workspace count: %d',
                perfdatas => [
                    { label => 'workspace_count', value => 'WorkspaceCount',
                      template => '%d', min => 0 },
                ],
            }
        },
        { label => 'folder-count', set => {
                key_values => [ { name => 'FolderCount' } ],
                output_template => 'Folder count: %d',
                perfdatas => [
                    { label => 'folder_count', value => 'FolderCount',
                      template => '%d', min => 0 },
                ],
            }
        },
        { label => 'file-count', set => {
                key_values => [ { name => 'FileCount' } ],
                output_template => 'File count: %d',
                perfdatas => [
                    { label => 'file_count', value => 'FileCount',
                      template => '%d', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "units:s"   => { name => 'units', default => '%' },
        "free"      => { name => 'free' },
    });

    return $self;
}

my $oid_TotalSystemMB = '.1.3.6.1.4.1.526.20.4.2.0';
my $oid_TotalAllocatedMB = '.1.3.6.1.4.1.526.20.4.3.0';
my $oid_TotalUsedMB = '.1.3.6.1.4.1.526.20.4.4.0';
my $oid_FileCount = '.1.3.6.1.4.1.526.20.4.5.0';
my $oid_FolderCount = '.1.3.6.1.4.1.526.20.4.6.0';
my $oid_WorkspaceCount = '.1.3.6.1.4.1.526.20.4.7.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_leef(oids => [ $oid_TotalSystemMB, $oid_TotalAllocatedMB,
                                                     $oid_TotalUsedMB, $oid_FileCount,
                                                     $oid_FolderCount, $oid_WorkspaceCount ], 
                                               nothing_quit => 1);
    
    $self->{global} = {};

    $self->{global} = { 
        TotalSystemMB => $results->{$oid_TotalSystemMB},
        TotalAllocatedMB => $results->{$oid_TotalAllocatedMB},
        TotalUsedMB => $results->{$oid_TotalUsedMB},
        FileCount => $results->{$oid_FileCount},
        FolderCount => $results->{$oid_FolderCount},
        WorkspaceCount => $results->{$oid_WorkspaceCount},
    };
}

1;

__END__

=head1 MODE

Check storage usage.

=over 8

=item B<--warning-usage>

Threshold warning for used allocated storage.

=item B<--critical-usage>

Threshold critical for used allocated storage.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=back

=cut
