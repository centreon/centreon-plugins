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

package cloud::linux::libvirt::local::mode::volume;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded convert_bytes trim);

my @_volume_keys = qw(pool_name volume_name capacity_bytes allocation_bytes usage_prct);

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($alloc_value, $alloc_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{allocation_bytes});
    my ($cap_value,   $cap_unit)   = $self->{perfdata}->change_bytes(value => $self->{result_values}->{capacity_bytes});

    return sprintf(
        'allocated: %s %s / capacity: %s %s (%.2f %%)',
        $alloc_value, $alloc_unit, $cap_value, $cap_unit,
        $self->{result_values}->{usage_prct}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'volumes', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_volume_output',
          message_multiple => 'All volumes are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{volumes} = [
        { label => 'allocation', nlabel => 'volume.allocation.bytes', set => {
                key_values => [ { name => 'allocation_bytes' }, { name => 'capacity_bytes' },
                                { name => 'usage_prct' }, { name => 'pool_name' }, { name => 'volume_name' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'allocation_bytes', template => '%s',
                      unit => 'B', min => 0, max => 'capacity_bytes', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'allocation-prct', nlabel => 'volume.allocation.percentage', set => {
                key_values => [ { name => 'usage_prct' }, { name => 'pool_name' }, { name => 'volume_name' } ],
                output_template => 'allocated: %.2f %%',
                perfdatas => [
                    { value => 'usage_prct', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    my $str = "Volume '" . $options{instance_value}->{pool_name} . '/' . $options{instance_value}->{volume_name} . "' ";
    $str .= "path: '" . $options{instance_value}->{path} . "', " if $self->{output}->is_verbose();
    return $str;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'pool-name:s'      => { name => 'pool_name',      default => '' },
        'volume-name:s'    => { name => 'volume_name',    default => '' },
        'include-pool:s'   => { name => 'include_pool',   default => '' },
        'exclude-pool:s'   => { name => 'exclude_pool',   default => '' },
        'include-volume:s' => { name => 'include_volume', default => '' },
        'exclude-volume:s' => { name => 'exclude_volume', default => '' },
        'include-path:s'   => { name => 'include_path',   default => '' },
        'exclude-path:s'   => { name => 'exclude_path',   default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{output}->option_exit(short_msg => '--pool-name cannot be used together with --include-pool or --exclude-pool.')
        if $self->{option_results}->{pool_name} ne '' && ($self->{option_results}->{include_pool} ne '' || $self->{option_results}->{exclude_pool} ne '');
    $self->{output}->option_exit(short_msg => '--volume-name cannot be used together with --include-volume or --exclude-volume.')
        if $self->{option_results}->{volume_name} ne '' && ($self->{option_results}->{include_volume} ne '' || $self->{option_results}->{exclude_volume} ne '');
}

sub manage_selection {
    my ($self, %options) = @_;

    my @pool_names;
    if ($self->{option_results}->{pool_name} ne '') {
        push @pool_names, $self->{option_results}->{pool_name};
    } else {
        my $stdout_pools = $options{custom}->execute_command(virsh_args => 'pool-list --all');
        foreach (split(/\n/, $stdout_pools)) {
            next if /^\s*(Name\s+State)\s*/i;
            next unless /^\s*(\S+)\s+(active|inactive)/i;
            my $pool = $1;
            next if is_excluded($pool, $self->{option_results}->{include_pool}, $self->{option_results}->{exclude_pool});
            push @pool_names, $pool;
        }
    }

    $self->{volumes} = {};

    foreach my $pool (@pool_names) {
        # virsh vol-list --pool <pool> --details
        #  Name              Path                              Type   Capacity    Allocation
        # -----------------------------------------------------------------------------------
        #  vol1.qcow2        /var/lib/libvirt/images/vol1...  file   10.74 GiB   3.22 GiB
        my $stdout = $options{custom}->execute_command(
            virsh_args => "vol-list --pool $pool --details"
        );
        foreach (split(/\n/, $stdout)) {
            next if /^\s*(Name\s+Path)\s*/i; # header
            # name  path  type  capacity_val capacity_unit  alloc_val alloc_unit
            next unless /^\s*(\S+)\s+(.+)\s+\S+\s+([\d.,]+)\s+(\S+)\s+([\d.,]+)\s+(\S+)\s*$/;
            my ($vol_name, $path, $cap_val, $cap_unit, $alloc_val, $alloc_unit) = ($1, $2, $3, $4, $5, $6);
            $path = trim($path);

            if ($self->{option_results}->{volume_name} ne '') {
                next unless $vol_name eq $self->{option_results}->{volume_name};
            } else {
                next if is_excluded($vol_name, $self->{option_results}->{include_volume}, $self->{option_results}->{exclude_volume});
            }
            next if is_excluded($path, $self->{option_results}->{include_path}, $self->{option_results}->{exclude_path});


            ($cap_val   = $cap_val)   =~ s/,/./g;
            ($alloc_val = $alloc_val) =~ s/,/./g;
            my $cap_bytes   = convert_bytes(value => $cap_val,   unit => $cap_unit);
            my $alloc_bytes = convert_bytes(value => $alloc_val, unit => $alloc_unit);

            $self->{volumes}->{$pool . '/' . $vol_name} = {
                pool_name        => $pool,
                volume_name      => $vol_name,
                path             => $path,
                capacity_bytes   => $cap_bytes,
                allocation_bytes => $alloc_bytes,
                usage_prct       => $cap_bytes > 0 ? $alloc_bytes / $cap_bytes * 100 : 0
            };
        }
    }

    $self->{output}->option_exit(short_msg => 'No volume found.')
        unless %{$self->{volumes}};
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @_volume_keys ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $item (sort { $a->{pool_name} cmp $b->{pool_name} || $a->{volume_name} cmp $b->{volume_name} } values %{$self->{volumes}}) {
        $self->{output}->add_disco_entry(map { $_ => $item->{$_} } @_volume_keys);
    }
}

1;

__END__

=head1 MODE

Check C<libvirt> storage volumes allocation (C<virsh vol-list --details>).

=over 8

=item B<--pool-name>

Check only this specific storage pool (skips pool-list discovery).
Cannot be used together with --include-pool or --exclude-pool.

=item B<--include-pool>

Filter storage pools by name (regexp).

=item B<--exclude-pool>

Exclude storage pools whose name matches this regexp.

=item B<--volume-name>

Check only this specific volume (exact match).
Cannot be used together with --include-volume or --exclude-volume.

=item B<--include-volume>

Filter volumes by name (regexp).

=item B<--exclude-volume>

Exclude volumes whose name matches this regexp.

=item B<--include-path>

Filter volumes by path (regexp).

=item B<--exclude-path>

Exclude volumes whose path matches this regexp.

=item B<--warning-allocation>

Warning threshold for allocated space (bytes).

=item B<--critical-allocation>

Critical threshold for allocated space (bytes).

=item B<--warning-allocation-prct>

Warning threshold for allocated space (%).

=item B<--critical-allocation-prct>

Critical threshold for allocated space (%).

=back

=cut
