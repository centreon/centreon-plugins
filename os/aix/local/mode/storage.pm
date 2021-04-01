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

package os::aix::local::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

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

sub prefix_storage_output {
    my ($self, %options) = @_;

    return "Storage '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'storages', type => 1, cb_prefix_output => 'prefix_storage_output', message_multiple => 'All storages are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{storages} = [
        { label => 'usage', nlabel => 'storage.space.usage.bytes', set => {
                key_values => [
                    { name => 'used_space' }, { name => 'free_space' }, 
                    { name => 'prct_used_space' }, { name => 'prct_free_space' },
                    { name => 'total_space' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'storage.space.free.bytes', display_ok => 0, set => {
                key_values => [
                    { name => 'free_space' }, { name => 'used_space' },
                    { name => 'prct_used_space' }, { name => 'prct_free_space' },
                    { name => 'total_space' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'free_space', template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'storageresource.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' } ],
                output_template => 'used: %.2f %%',
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
        'filter-fs:s'         => { name => 'filter_fs' },
        'filter-mount:s'      => { name => 'filter_mount' },
        'space-reservation:s' => { name => 'space_reservation' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'df',
        command_options => '-P -k 2>&1'
    );

    $self->{storages} = {};
    my @lines = split /\n/, $stdout;
    # Header not needed
    shift @lines;
    foreach my $line (@lines) {
        next if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)/);
        my ($fs, $size, $used, $available, $percent, $mount) = ($1, $2, $3, $4, $5, $6);

        next if (defined($self->{option_results}->{filter_fs}) && $self->{option_results}->{filter_fs} ne '' &&
            $fs !~ /$self->{option_results}->{filter_fs}/);
        next if (defined($self->{option_results}->{filter_mount}) && $self->{option_results}->{filter_mount} ne '' &&
            $mount !~ /$self->{option_results}->{filter_mount}/);

        next if ($size !~ /^\d+$/ || $used !~ /^\d+$/ || $available !~ /^\d+$/);
        next if ($size == 0);

        $size = $size * 1024;
        my $reserved_value = 0;
        if (defined($self->{option_results}->{space_reservation})) {
            $reserved_value = $self->{option_results}->{space_reservation} * $size / 100;
        }
        my $used_space = $used * 1024;
        my $free_space = $size - $used_space - $reserved_value;
        my $prct_used_space = $used_space * 100 / ($size - $reserved_value);
        my $prct_free_space = 100 - $prct_used_space;
        # limit to 100. Better output.
        if ($prct_used_space > 100) {
            $free_space = 0;
            $prct_used_space = 100;
            $prct_free_space = 0;
        }

        $self->{storages}->{$mount} = {
            display => $mount,
            total_space => $size,
            used_space => $used_space,
            free_space => $free_space,
            prct_used_space => $prct_used_space,
            prct_free_space => $prct_free_space
        };
    }

    if (scalar(keys %{$self->{storages}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No storage found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check storage usages.
Command used: df -P -k 2>&1

=over 8

=item B<--filter-fs>

Filter filesystem (regexp can be used).

=item B<--filter-mount>

Filter mountpoint (regexp can be used).

=item B<--space-reservation>

Some filesystem has space reserved (like ext4 for root).
The value is in percent of total (Default: none).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
