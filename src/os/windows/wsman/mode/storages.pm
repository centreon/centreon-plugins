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

package os::windows::wsman::mode::storages;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
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

sub prefix_storage_output {
    my ($self, %options) = @_;

    return sprintf(
        "Storage '%s' [type: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'storages', type => 1, cb_prefix_output => 'prefix_storage_output', message_multiple => 'All storages are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'detected', nlabel => 'storages.detected.count', display_ok => 0, set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'Storages detected: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{storages} = [
        { label => 'space-usage', nlabel => 'storage.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'storage.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'storage.space.usage.percentage', display_ok => 0, set => {
                 key_values => [ { name => 'prct_used' }, { name => 'free' }, { name => 'used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
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
        'filter-name:s' => { name => 'filter_name' },
        'filter-type:s' => { name => 'filter_type', default => 'localDisk' }
    });

    return $self;
}

my $map_types = {
    0 => 'unknown',
    1 => 'noRootDirectory',
    2 => 'removableDisk',
    3 => 'localDisk',
    4 => 'networkDrive',
    5 => 'compactDisc',
    6 => 'ramDisk'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => 'Select Capacity,DeviceID,DriveLetter,DriveType,FileSystem,FreeSpace,Label,Name from Win32_Volume',
        result_type => 'array'
    );

#    'CLASS: Win32_Volume',
#    'Capacity;DeviceID;DriveLetter;DriveType;FileSystem;FreeSpace;Label;Name',
#    '32210153472;\\\\?\\Volume{1952b268-0000-0000-0000-100000000000}\\;C:;3;NTFS;14982889472;(null);C:\\'

    $self->{global} = { detected => 0 };
    $self->{storages} = {};
    foreach (@$results) {
        my $type = $map_types->{ $_->{DriveType} };

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{Name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $type !~ /$self->{option_results}->{filter_type}/);

        next if (!defined($_->{Capacity}) || $_->{Capacity} eq '' || $_->{Capacity} == 0);

        my ($total, $free) = ($_->{Capacity}, $_->{FreeSpace});
        $self->{storages}->{ $_->{Name} } = {
            name => $_->{Name},
            type => $type,
            total => $total,
            used => $total - $free,
            free => $free,
            prct_free => $free * 100 /  $total,
            prct_used => 100 - ($free * 100 /  $total)
        };
        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check storages.

=over 8

=item B<--filter-name>

Filter storages by name (can be a regexp).

=item B<--filter-type>

Filter storages by type (can be a regexp) (default: 'localDisk').

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage' (B), 'space-usage-free' (B), 'space-usage-prct'.

=back

=cut
