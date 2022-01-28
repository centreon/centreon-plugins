#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package os::windows::wsman::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %storage_types_manage = (
    'unknown'         => 0,
    'noRootDirectory' => 1,
    'removableDisk'   => 2,
    'localDisk'       => 3,
    'networkDrive'    => 4,
    'compactDisc'     => 5,
    'ramDisk'         => 6
);

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my ($label, $nlabel) = ('used', $self->{nlabel});
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        ($label, $nlabel) = ('free', 'storage.space.free.bytes');
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        nlabel => $nlabel,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
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
    $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value,
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_size'};
    
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    
    # limit to 100. Better output.
    if ($self->{result_values}->{prct_used} > 100) {
        $self->{result_values}->{free} = 0;
        $self->{result_values}->{prct_used} = 100;
        $self->{result_values}->{prct_free} = 0;
    }
    return 0;
}

sub prefix_storage_output {
    my ($self, %options) = @_;

    return "Storage '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'storage', type => 1, cb_prefix_output => 'prefix_storage_output', message_multiple => 'All storages are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'count', nlabel => 'storage.partitions.count', display_ok => 0, set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Partitions count: %d',
                perfdatas => [
                    { label => 'count', template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{storage} = [
        { label => 'usage', nlabel => 'storage.space.usage.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'size' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'units:s'                 => { name => 'units', default => '%' },
        'free'                    => { name => 'free' },
        'storage:s'               => { name => 'storage'},
        'filter-storage-type:s'   => { name => 'filter_storage_type', default => 'localDisk' },
    });

    return $self;
}


sub manage_selection {
    my ($self, %options) = @_;
    $self->{wsman} = $options{wsman};
   
    my $WQL = 'Select Capacity,DeviceID,DriveLetter,DriveType,FileSystem,FreeSpace,Label,Name from Win32_Volume where DriveType=' . $storage_types_manage{$self->{option_results}->{filter_storage_type}} ;

    if (defined($self->{option_results}->{storage})) {
        $WQL = $WQL . ' and DriveLetter like "' . $self->{option_results}->{storage} . '%"';
    }

    $self->{result} = $self->{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => $WQL,
        result_type => 'hash',
        hash_key => 'Name'
    );

#    'CLASS: Win32_Volume',
#    'Capacity;DeviceID;DriveLetter;DriveType;FileSystem;FreeSpace;Label;Name',
#    '32210153472;\\\\?\\Volume{1952b268-0000-0000-0000-100000000000}\\;C:;3;NTFS;14982889472;(null);C:\\'
    if (scalar(keys %{$self->{result}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't get storages...");
        $self->{output}->option_exit();
    }

    $self->{global}->{count} = 0;
    $self->{storage} = {};
    foreach my $name (sort(keys %{$self->{result}})) {
        my $size = $self->{result}->{$name}->{Capacity};
        my $name_storage = $self->{result}->{$name}->{DriveLetter};
        my $type = $self->{result}->{$name}->{DriveType};
        my $fileSystem = $self->{result}->{$name}->{FileSystem};
        my $free = $self->{result}->{$name}->{FreeSpace};
        my $used = $size - $free;

        $self->{storage}->{$self->{global}->{count}} = {
            display => $name_storage,
            size => $size,
            used => $used,
        };
        $self->{global}->{count}++;
    }
    
}

1;

__END__

=head1 MODE

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--storage>

Set the storage ex: C, D,... (empty means 'check all storage').

=item B<--filter-storage-type>

Filter storage types (Default: 'localDisk').
Can be: unknown, noRootDirectory, removableDisk, localDisk, networkDrive, compactDisc, ramDisk.
See: https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-logicaldisk

=back

=cut
